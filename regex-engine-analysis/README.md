# regex-engine-analysis — Experiments for §4

Here, we measure whether super-linear regexes improved performance in the latest versions of programming languages and their regex engines and quantify the effectiveness of ReDoS defenses (if any).

## Directory map

- `scripts/`: Harnesses and Dockerfiles for the nine language runtimes we test. See below.
- `results/`: Contains the results of our experiments.
- `sl-regex-corpus/`: The super-linear regex corpus we use in our experiments with corresponding input strings. Both the full dataset and the 1000‑regex sample used in the paper are available.
- `plot.py`: Plots the performance of regex matching in old vs. latest engines in different programming languages (Figure 5 in the paper). You need to have `matplotlib` and `numpy` installed to run this script.

### Inside `scripts/`

- One sub‑directory per language (e.g., `python/`, `java/`). Each holds:
  - There are two Dockerfiles, one is for the older version of the language runtime, and the other is for a newer version (i.e., before and after the ReDoS defense was possibly introduced). The naming convention is `Dockerfile.<version>`.
  - Small helper scripts to measure the time taken to match each regex in our corpus against each corresponding input string.
- `experiment.sh`: The main script to run the experiments. The results are saved in the `results/` directory as JSON files in each language sub‑directory.
- 
However, you can also run the experiments manually for specific languages. For example, to run the experiments for Node.js v15.14.0 (old version) and v22.2.0 (new version), you can run the following commands:

```bash
docker build -f javascript/Dockerfile.NodeV15_14_0 -t node-v15.14.0-regex .
docker run --volume $PWD/javascript/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm node-v15.14.0-regex
docker rmi node-v15.14.0-regex

docker build -f javascript/Dockerfile.NodeV22_2_0 -t node-v22.2.0-regex .
docker run --volume $PWD/javascript/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm node-v22.2.0-regex
docker rmi node-v22.2.0-regex
```

Results will be saved in `javascript/results/`.

### Data Format

The super-linear regex corpus that is generated with the help of [`vuln-regex-detector`](https://github.com/davisjam/vuln-regex-detector) stores the following list of dictionaries in JSON format:

```json
[
  {
    "regex": <regex that is predicted to be super-linear>,
    "inputs": [
      {
        "prefix": [
            <prefix of the input string that will cause super-linear behavior 
            when matched against the regex>
        ],
        "pump": [
            <a string that is repeated one or more times and appended to the prefix to create a super-linear input>
        ],
        "suffix": <suffix of the input string that will be appended to the prefix + pump>
      },
      ...
    ],
    "complexity": <the predicted time complexity of the regex (i.e., exponential or polynomial)>
  },
  ...
]
```

For result files, the structure is the same, but each input contains a dictionary called `results` that logs the matching information:

```json
{
  "regex": <regex>,
  "inputs": [
    {
      "prefix": [...],
      "pump": [...],
      "suffix": <...>,
      "results": {
        "pumped": <how many times the pump was repeated>,
        "string_length": <length of the full input string (prefix + pump + suffix)>,
        "time_taken": <time taken to match the regex against the input string in milliseconds>,
        "match": <boolean indicating whether the regex matched the input string>,
        "timeout": <boolean indicating whether the matching operation timed out>,
        "error": <any error message if the matching operation failed>
      }
    },
    ...
  ],
  "complexity": <...>
}
```
