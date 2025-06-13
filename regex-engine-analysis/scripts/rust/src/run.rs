
extern crate fork;
extern crate nix;
use std::fs::File;
use std::time::{Duration, Instant};
use std::env;
use regex::Regex;
use serde_json::{Value, from_str, to_string_pretty, json};
use std::thread;
use std::sync::mpsc;

use fork::{fork, Fork};
use std::io::{self, Write, Read};
use std::os::unix::io::{FromRawFd, RawFd};
use std::process;

#[derive(Debug)]
struct RegexTimeout;

fn exec_regex_with_timeout(pattern: &str, input: &str, timeout_secs: u64) -> Result<bool, String> {
    let (pipe_in, pipe_out) = nix::unistd::pipe().expect("Failed to create pipe");

    match fork() {
        Ok(Fork::Parent(child)) => {
            // Close write end of the pipe in parent
            nix::unistd::close(pipe_out).expect("Failed to close write end of the pipe");

            // Handle timeout in parent
            let mut read_fd = unsafe { std::fs::File::from_raw_fd(pipe_in as RawFd) };
            let mut buffer = [0; 1];
            let start_time = std::time::Instant::now();
            while start_time.elapsed() < Duration::from_secs(timeout_secs) {
                if let Ok(_) = read_fd.read(&mut buffer) {
                    if buffer[0] == 1 {
                        return Ok(true);
                    } else {
                        return Ok(false);
                    }
                }
            }
            Err("Timeout occurred".to_string())
        },
        Ok(Fork::Child) => {
            // Close read end of the pipe in child
            nix::unistd::close(pipe_in).expect("Failed to close read end of the pipe");

            // Perform regex evaluation
            let re = Regex::new(pattern).unwrap();
            let matched = re.is_match(input);
            let mut write_fd = unsafe { std::fs::File::from_raw_fd(pipe_out as RawFd) };

            // Write result to pipe
            write_fd.write_all(&[matched as u8]).expect("Failed to write to pipe");
            process::exit(0); // Exit child process cleanly
        },
        Err(_) => {
            return Err("Fork failed".to_string());
        }
    }
}

pub fn process_dataset() {
    let experiment_name = env::var("EXPERIMENT_NAME").unwrap_or_else(|_| "default".to_string());
    let _experiment_type = if experiment_name == "Rust1_78_0" { "new" } else { "old" };
    let dataset_file_name = env::var("DATASET_FILE").unwrap_or_else(|_| "default".to_string());

    let mut file = File::open(format!("./dataset/{}", dataset_file_name)).expect("Cannot open dataset.json");
    let mut data = String::new();
    file.read_to_string(&mut data).expect("Cannot read dataset.json");

    let mut dataset: Value = from_str(&data).expect("Cannot parse JSON");
    let dataset_len = dataset.as_array().unwrap().len();  // Store length here

    let times_to_pump = vec![1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10_i32.pow(4), 25000, 10_i32.pow(5), 10_i32.pow(6)];

    for (i, data) in dataset.as_array_mut().unwrap().iter_mut().enumerate() {
        println!("[{}/{}] {} is under test...", i + 1, dataset_len, data["regex"].as_str().unwrap());

        let pattern = format!(
            "{}{}{}",
            if data["regex"].as_str().unwrap().starts_with('^') { "" } else { "^" },
            data["regex"].as_str().unwrap(),
            if data["regex"].as_str().unwrap().ends_with('$') { "" } else { "$" }
        );

        let regex_test = match Regex::new(&pattern) {
            Ok(re) => re,
            Err(_) => {
                println!("Unsupported regex pattern: {}", pattern);
                continue;
            }
        };

        // print length of the data inputs
        println!("Number of inputs: {}", data["inputs"].as_array().unwrap().len());

        for input in data["inputs"].as_array_mut().unwrap() {
            println!("Running on: {:?}", input);

            input["results"] = Value::Array(vec![]);

            for j in &times_to_pump {
                let pumped_string = input["prefix"].as_array().unwrap()
                    .iter().zip(input["pump"].as_array().unwrap())
                    .map(|(item, pump)| format!("{}{}", item.as_str().unwrap(), pump.as_str().unwrap().repeat(*j as usize)))
                    .collect::<Vec<_>>().join("")
                    + input["suffix"].as_str().unwrap();

                let start_time = Instant::now();

                match exec_regex_with_timeout(&pattern, &pumped_string, 5) {
                    Ok(matched) => {
                        let elapsed_time = start_time.elapsed().as_millis();
                        println!("String Length: {} Pumped: {} Match: {} Time: {}", pumped_string.len(), j, matched, elapsed_time);
                        input["results"].as_array_mut().unwrap().push(json!({
                            "string_length": pumped_string.len(),
                            "pumped": j,
                            "time": elapsed_time,
                            "match": matched,
                            "timeout": false,
                            "error": null
                        }));
                    },
                    Err(e) => {
                        let elapsed_time = start_time.elapsed().as_millis();
                        println!("Error: {} String Length: {} Pumped: {} Match: {} Time: {}", e, pumped_string.len(), j, false, elapsed_time);
                        input["results"].as_array_mut().unwrap().push(json!({
                            "string_length": pumped_string.len(),
                            "pumped": j,
                            "time": elapsed_time,
                            "match": false,
                            "timeout": true,
                            "error": e.to_string()
                        }));

                        break;
                    }
                }
            }
        }

        // system exit for debug
        // std::process::exit(0);
    }

    let output = to_string_pretty(&dataset).expect("Cannot serialize results");
    File::create(format!("./results/{}_results_{}.json", dataset_file_name, experiment_name))
        .expect("Cannot create results file")
        .write_all(output.as_bytes())
        .expect("Cannot write results to file");

    println!("Experiments completed.");
}
