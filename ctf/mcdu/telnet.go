package main


import (
	"github.com/reiver/go-telnet"
	"github.com/reiver/go-telnet/telsh"
	"os/exec"
	"io"
	"fmt"
)

func cdlsHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	if args[0] == "help" {
		fmt.Fprintf(stdout, `

            __________
           |  __  __  |
           |          |
           |       _  |
           |      |_| |
           |          |
           |  __  __¬ |
           |          |
           |          |
           |          |
           |  __  __  |
           |__________|


Cockpit Door Locking System (CDLS) debug interface

Available commands:
    cdls unlock $CODE: Tries to unlock the door with $CODE (range is [A-Z{}])
    cdls help:         Shows this message

`)
	} else if args[0] == "unlock" {
		return exec.Command("/cdls/unlock", args[1]).Run()
	}
	return nil;
}

func xctHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	if len(args) > 0 {
		return exec.Command("/bin/bash", "-c", args[0]).Start()
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
	return telsh.PromoteHandlerFunc(xctHandler, "cd /root/XCT/bin; DISPLAY=:0 ./XCT")
}

func cdlsProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	if len(args) < 2 {
		args = []string{"help"}
	}
	return telsh.PromoteHandlerFunc(cdlsHandler, args...)
}

func elseProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(xctHandler, args...)
}

func main() {
	addr := ":23"
	shellHandler := telsh.NewShellHandler()
	shellHandler.WelcomeMessage = `


               __|__                      __|__
        --o--o--(_)--o--o--        --o--o--(_)--o--o--


A3xx Multi-Function Control and Display Unit (MCDU) debug interface

Available commands:
    xct:  Launchs the eXtendedCAN Tool (XCT)
    cdls: Sends a command to the cockpit door locking system (CDLS)
    exit: Exits

`
	shellHandler.Register("xct", telsh.ProducerFunc(xctProducer))
	shellHandler.Register("cdls", telsh.ProducerFunc(cdlsProducer))
	shellHandler.RegisterElse(telsh.ProducerFunc(elseProducer))
	if err := telnet.ListenAndServe(addr, shellHandler); nil != err {
		panic(err)
	}
}
