package main


import (
	"github.com/reiver/go-telnet"
	"github.com/reiver/go-telnet/telsh"
	"os/exec"
	"io"
	"fmt"
)

func xctHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	if len(args) > 0 {
		cmd := exec.Command("/bin/bash", "-c", args[0]);
		cmd.Stdout = stdout
		return cmd.Run()
	} else {
		fmt.Fprintf(stdout, "Error: %v", args)
		return nil
	}
}

func elseHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	fmt.Printf("ERROR %v\r\n", args)
	fmt.Fprintf(stdout, "Error: %v", args)
	return nil
}

func xctProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(xctHandler, []string{"cd /root/XCT/bin; DISPLAY=:0 ./XCT"}...)
}

func elseProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(xctHandler, args...)
}

func main() {
	addr := ":23"
	shellHandler := telsh.NewShellHandler()
	shellHandler.WelcomeMessage = `

A320 Multi-Function Control and Display Unit (debug) interface

Available commands:
    xct: launch the the eXtendedCAN Tool (XCT)
    exit: exit
`
	shellHandler.Register("xct", telsh.ProducerFunc(xctProducer))
	shellHandler.RegisterElse(telsh.ProducerFunc(elseProducer))
	if err := telnet.ListenAndServe(addr, shellHandler); nil != err {
		panic(err)
	}
}
