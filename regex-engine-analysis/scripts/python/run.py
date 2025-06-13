import json
import os
import re
import time
from contextlib import contextmanager

# Set experiment variables
experiment_name = os.getenv('EXPERIMENT_NAME')
experiment_type = "old" if experiment_name == "Python3_6" else "new"
dataset_file_name = os.getenv('DATASET_FILE')

# Load dataset
with open('./dataset/' + dataset_file_name) as file:
    dataset = json.load(file)

@contextmanager
def timeout(seconds):
    from signal import signal, alarm, SIGALRM
    def handler(signum, frame):
        raise TimeoutError('Regex operation timed out.')

    signal(SIGALRM, handler)
    alarm(seconds)
    try:
        yield
    finally:
        alarm(0)

def exec_regex_with_timeout(regex, input_str, timeout_duration):
    try:
        with timeout(timeout_duration):
            match = regex.search(input_str)
            return {"result": match}
    except TimeoutError:
        raise TimeoutError('Regex operation timed out.')

def process_dataset():
    times_to_pump = [1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10**4, 25000, 10**5, 10**6]

    for i, data in enumerate(dataset):
        print(f"[{i + 1}/{len(dataset)}] {data['regex']} is under test...")

        pattern = data['regex']

        # Ensure a full match
        if not pattern.startswith('^'):
            pattern = '^' + pattern

        if not pattern.endswith('$'):
            pattern = pattern + '$'

        try:
            regex = re.compile(pattern)
        except re.error as error:
            print(f"Unsupported regex pattern: {pattern}")
            continue

        for input_item in data['inputs']:
            print(f"Running on: {input_item}")

            input_item["results"] = []

            for j in times_to_pump:
                pumped_string = ''.join([item + input_item['pump'][k] * j for k, item in enumerate(input_item['prefix'])]) + input_item['suffix']
                start_time = time.monotonic()

                try:
                    result = exec_regex_with_timeout(regex, pumped_string, 5) # 5 seconds timeout
                    end_time = time.monotonic()
                    elapsed_time = (end_time - start_time) * 1000
                    print(f"String Length: {len(pumped_string)} Pumped: {j} Match: {result['result'] is not None} Time: {elapsed_time}")
                    input_item["results"].append({
                        "string_length": len(pumped_string),
                        "pumped": j,
                        "time": elapsed_time,
                        "match": result['result'] is not None,
                        "timeout": False,
                        "error": None
                    })
                except Exception as error:
                    end_time = time.monotonic()
                    elapsed_time = (end_time - start_time) * 1000
                    print(f"Error: {error} String Length: {len(pumped_string)} Pumped: {j} Match: False Time: {elapsed_time}")
                    input_item["results"].append({
                        "string_length": len(pumped_string),
                        "pumped": j,
                        "time": elapsed_time,
                        "match": False,
                        "timeout": True,
                        "error": str(error)
                    })
                    # Optimization: Break out of the loop if the timeout is reached, since the next iterations will also timeout
                    break

    # Optionally dump results to a file
    with open(f"./results/{dataset_file_name.replace('.json', '')}_results_{experiment_name}.json", 'w') as file:
        json.dump(dataset, file, indent=4)

    print('Experiments completed.')

try:
    process_dataset()
except Exception as error:
     print(f"Failed to process dataset: {error}")
