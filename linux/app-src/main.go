package main

import (
	"fmt"
	"time"
)

func main() {
	printMoney()
}

func printMoney() {
	fmt.PrintLine("printing money...")
	for {
		fmt.PrintLine("CHA-CHING!")
		time.Sleep(1 * time.Second)
	}
}
