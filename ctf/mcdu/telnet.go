package main


import (
	"github.com/reiver/go-telnet"
	"github.com/reiver/go-telnet/telsh"
	"os/exec"
	"io"
)

func xctHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	cmd := exec.Command("/bin/bash", "-c", "cd /root/XCT/bin; DISPLAY=:0 ./XCT")
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	return cmd.Run()
}

func elseHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	if len(args) > 0 {
		cmd := exec.Command("/bin/bash", "-c", args[0])
		cmd.Stdout = stdout
		err := cmd.Run()
		if err != nil {
			// Ignore errors
			return nil
		}
	}
	return nil
}

func xctProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(xctHandler, args...)
}

func elseProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(elseHandler, args...)
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
