package main

import (
	"os"
	"syscall"

	"github.com/11notes/docker-util"
)

func main(){
	_ = eleven.Container.EnvToFile("RCLONE_CONFIG", "/rclone/etc/default.conf")	
	if err := syscall.Exec("/usr/local/bin/rclone", eleven.Container.Command([]string{"rclone", "--rc", "--rc-addr", "0.0.0.0:5572", "--rc-enable-metrics", "--config", "/rclone/etc/default.conf"}), os.Environ()); err != nil {
		os.Exit(1)
	}
}