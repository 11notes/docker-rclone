package main

import (
	"github.com/11notes/go-eleven"
)

func main(){
	_ = eleven.Container.EnvToFile("RCLONE_CONFIG", "/rclone/etc/default.conf")
	eleven.Container.Run("/usr/local/bin", "rclone", eleven.Container.MergeCommand([]string{"--rc", "--rc-addr", "0.0.0.0:5572", "--rc-enable-metrics", "--config", "/rclone/etc/default.conf"}), []string{})
}