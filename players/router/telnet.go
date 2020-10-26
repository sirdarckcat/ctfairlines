package main


import (
	"github.com/reiver/go-telnet"
	"github.com/reiver/go-telnet/telsh"
	"os/exec"
	"io"
	"time"
	"fmt"
)

var ban = time.Now()
var attempts = 0

func dnsHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	fmt.Fprintf(stderr, "For the simulator, use docker-compose --dns=1.1.1.1 up instead.\r\n")
	return nil
}

func unlockHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	if ban.After(time.Now()) {
		return nil
	}
	if attempts >= 3 {
		// Lock the user for 5 minutes after 3 attempts
		five, _ := time.ParseDuration("5m")
		ban = time.Now().Add(five)
		return nil
	}
	attempts += 1
	return exec.Command("./unlock.sh", args...).Run()
}

func dnsProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(dnsHandler, args...)
}

func unlockProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{
	return telsh.PromoteHandlerFunc(unlockHandler, args...)
}

func main() {
	addr := ":23"
	shellHandler := telsh.NewShellHandler()
	shellHandler.WelcomeMessage = `
cmds:
      dns $dnsServer - sets the DNS server to $dnsServer
      unlock $doorPassword - attempts to unlock the cockpit with $doorPassword
`
	shellHandler.Register("dns", telsh.ProducerFunc(dnsProducer))
	shellHandler.Register("unlock", telsh.ProducerFunc(unlockProducer))
	if err := telnet.ListenAndServe(addr, shellHandler); nil != err {
		panic(err)
	}
}
