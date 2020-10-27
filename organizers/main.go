package main

import (
	"fmt"
	"os"
	"net"
	"time"
	"golang.org/x/net/context"
	"github.com/armon/go-socks5"
)

type UserResolver struct {}

func (d UserResolver) Resolve(ctx context.Context, name string) (context.Context, net.IP, error) {
	r := &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{
				Timeout: time.Millisecond * time.Duration(10000),
			}
			return d.DialContext(ctx, "udp", os.Args[2])
		},
	}
	ip, err := r.LookupIP(context.Background(), "ip4", name)
	if len(ip) < 1 {
		return ctx, nil, err
	}
	return ctx, ip[0], err
}

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Oops! not enough arguments $proxySocket $dnsIp:$dnsPort")
		return
	}

	conf := &socks5.Config{
		Resolver: UserResolver{},
	}
	server, err := socks5.New(conf)
	if err != nil {
		panic(err)
	}
	
	if err := server.ListenAndServe("unix", os.Args[1]); err != nil {
		panic(err)
	}
}
