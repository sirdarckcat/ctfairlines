package main


import (
	"github.com/reiver/go-oi"
	"github.com/reiver/go-telnet"
	"github.com/reiver/go-telnet/telsh"

	"io"
	"time"
)


func danceHandler(stdin io.ReadCloser, stdout io.WriteCloser, stderr io.WriteCloser, args ...string) error {
	for i:=0; i<20; i++ {
		oi.LongWriteString(stdout, "\r⠋")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠙")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠹")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠸")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠼")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠴")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠦")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠧")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠇")
		time.Sleep(50*time.Millisecond)

		oi.LongWriteString(stdout, "\r⠏")
		time.Sleep(50*time.Millisecond)
	}
	oi.LongWriteString(stdout, "\r \r\n")

	return nil
}

func danceProducer(ctx telnet.Context, name string, args ...string) telsh.Handler{

	return telsh.PromoteHandlerFunc(danceHandler)
}

func main() {
	shellHandler := telsh.NewShellHandler()
	shellHandler.Register("dance", telsh.ProducerFunc(danceProducer))
	addr := ":5555"
	if err := telnet.ListenAndServe(addr, shellHandler); nil != err {
		panic(err)
	}
}
