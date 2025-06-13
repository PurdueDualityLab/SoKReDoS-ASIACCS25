package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"regexp"
	"time"
	"os"
	"os/exec"
	"bytes"
	"strings"
)

var (
	experimentName = os.Getenv("EXPERIMENT_NAME")
	experimentType = "old"
	datasetFilename = os.Getenv("DATASET_FILE")
	dataset []Data
)

type Input struct {
	Prefix  []string `json:"prefix"`
	Pump    []string `json:"pump"`
	Suffix  string   `json:"suffix"`
	Results []Result `json:"results"`
}

type Data struct {
	Regex  string  `json:"regex"`
	Inputs []Input `json:"inputs"`
}

type Result struct {
	StringLength int     `json:"string_length"`
	Pumped       int     `json:"pumped"`
	Time         float64 `json:"time"`
	Match        bool    `json:"match"`
	Timeout      bool    `json:"timeout"`
	Error        string  `json:"error"`
}

func init() {
	if experimentName == "Go1_22_4" {
		experimentType = "new"
	}
}

func execRegexWithTimeout(pattern string, input string, timeout time.Duration) (bool, error) {
	cmd := exec.Command("go", "run", "regex_match.go", pattern, input)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	err := cmd.Start()
	if err != nil {
		return false, err
	}

	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()

	select {
	case <-time.After(timeout):
		if err := cmd.Process.Kill(); err != nil {
			return false, fmt.Errorf("Timeout failed: %v", err)
		}
		return false, fmt.Errorf("Regex operation timed out.")
	case err := <-done:
		if err != nil {
			return false, err
		}
	}

	match := out.String() == "true\n"
	return match, nil
}

// func execRegexWithTimeout(re *regexp.Regexp, input string, timeout time.Duration) (bool, error) {
// 	ctx, cancel := context.WithTimeout(context.Background(), timeout)
// 	defer cancel()

// 	resultChan := make(chan bool, 1)
// 	errorChan := make(chan error, 1)

// 	go func() {
// 		result := re.MatchString(input)
// 		resultChan <- result
// 	}()

// 	select {
// 	case <-ctx.Done():
// 		return false, fmt.Errorf("Regex operation timed out.")
// 	case result := <-resultChan:
// 		return result, nil
// 	case err := <-errorChan:
// 		return false, err
// 	}
// }

func processDataset() {
	timesToPump := []int{1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10000, 25000}

	for i, data := range dataset {
		fmt.Printf("[%d/%d] %s is under test...\n", i+1, len(dataset), data.Regex)

		pattern := data.Regex
		if !strings.HasPrefix(data.Regex, "^") {
			pattern = "^" + pattern
		}
		if !strings.HasSuffix(data.Regex, "$") {
			pattern = pattern + "$"
		}

		_, err := regexp.Compile(pattern)
		if err != nil {
			fmt.Printf("Unsupported regex pattern: %s\n", pattern)
			continue
		}

		for j := range data.Inputs {
			input := &data.Inputs[j]
			fmt.Printf("Running on: %+v\n", input)

			input.Results = []Result{}

			for _, j := range timesToPump {
				pumpedString := ""
				for k, item := range input.Prefix {
					pumpedString += item + stringRepeat(input.Pump[k], j)
				}
				pumpedString += input.Suffix

				startTime := time.Now()

				result, err := execRegexWithTimeout(pattern, pumpedString, 5*time.Second)
				elapsedTime := time.Since(startTime).Seconds() * 1000
				if err != nil {
					fmt.Printf("Error: %s String Length: %d Pumped: %d Match: false Time: %.2f\n", err, len(pumpedString), j, elapsedTime)
					input.Results = append(input.Results, Result{
						StringLength: len(pumpedString),
						Pumped:       j,
						Time:         elapsedTime,
						Match:        false,
						Timeout:      true,
						Error:        err.Error(),
					})
					break
				}

				fmt.Printf("String Length: %d Pumped: %d Match: %v Time: %.2f\n", len(pumpedString), j, result, elapsedTime)
				input.Results = append(input.Results, Result{
					StringLength: len(pumpedString),
					Pumped:       j,
					Time:         elapsedTime,
					Match:        result,
					Timeout:      false,
					Error:        "",
				})
			}
		}
	}

	resultFile := fmt.Sprintf("./results/%s_results_%s.json", datasetFilename[0:len(datasetFilename)-5], experimentName)
	resultData, _ := json.MarshalIndent(dataset, "", "  ")
	ioutil.WriteFile(resultFile, resultData, 0644)

	fmt.Println("Experiments completed.")
}

func stringRepeat(s string, count int) string {
	result := ""
	for i := 0; i < count; i++ {
		result += s
	}
	return result
}

func main() {
	data, err := ioutil.ReadFile("./dataset/" + datasetFilename)
	if err != nil {
		fmt.Printf("Failed to read dataset file: %v\n", err)
		return
	}

	err = json.Unmarshal(data, &dataset)
	if err != nil {
		fmt.Printf("Failed to parse dataset JSON: %v\n", err)
		return
	}

	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Failed to process dataset: %v\n", r)
		}
	}()

	processDataset()
}
