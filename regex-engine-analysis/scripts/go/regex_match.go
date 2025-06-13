package main

import (
	"fmt"
	"os"
	"regexp"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Println("false")
		return
	}

	pattern := os.Args[1]
	input := os.Args[2]

	regex, err := regexp.Compile(pattern)
	if err != nil {
		fmt.Println("false")
		return
	}

	match := regex.MatchString(input)
	if match {
		fmt.Println("true")
	} else {
		fmt.Println("false")
	}
}
