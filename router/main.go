package main

import (
	"fmt"
	"os"
	"net"
	"time"
	"golang.org/x/net/context"
	"github.com/armon/go-socks5"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Oops! not enough arguments $proxySocket $dnsIp:$dnsPort")
		return
	}
	net.DefaultResolver = &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{
				Timeout: time.Millisecond * time.Duration(10000),
			}
			return d.DialContext(ctx, "udp", os.Args[2])
		},
	}
	server, err := socks5.New(&socks5.Config{})
	if err != nil {
		panic(err)
	}
	
	if err := server.ListenAndServe("unix", os.Args[1]); err != nil {
		panic(err)
	}
}
