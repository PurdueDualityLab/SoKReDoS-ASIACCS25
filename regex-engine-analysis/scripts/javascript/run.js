const experimentName = process.env.EXPERIMENT_NAME;
const experimentType = experimentName === "NodeV15_14_0" ? "old" : "new";

const datasetFileName = process.env.DATASET_FILE;
const dataset = require('./dataset/' + datasetFileName);

const { Worker } = require('worker_threads');

const execRegexWithTimeout = (regex, input, timeout) => {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./regexWorker.js');
    worker.postMessage({ regexString: regex.source, input: input, linearTag: experimentType === "new"});

    const timer = setTimeout(() => {
      worker.terminate();
      reject(new Error('Regex operation timed out.'));
    }, timeout);

    worker.on('message', (result) => {
      clearTimeout(timer);
      worker.terminate(); // Terminate the worker as we got the result
      resolve({
        result: result,
      });
    });

    worker.on('error', (err) => {
      clearTimeout(timer);
      worker.terminate(); // Ensure to terminate the worker on error
      reject(err);
    });

    // worker.on('exit', (code) => {
    //   clearTimeout(timer);
    //   if (code !== 0 && !worker.threadiD) {
    //     reject(new hook.Error(`Worker stopped with exit code ${code}`));
    //   }
    // });
  });
};

const processDataset = async () => {
  var timesToPump = [1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10**4, 25000, 10**5, 10**6];

  for (let i = 0; i < dataset.length; i++) {
    const data = dataset[i];

    console.log(`[${i + 1}/${dataset.length}] ${data.regex} is under test...`);

    // Ensure a full match
    let pattern= (data.regex.startsWith("^") ? "" : "^") + data.regex + (data.regex.endsWith("$") ? "" : "$");

    try {
      var regex = new RegExp(pattern);
    }
    catch (error) {
      console.log("Unsupported regex pattern:", pattern);
      continue;
    }

    let inputs = data.inputs;

    for (let input of inputs) {
      console.log('Running on:', input);
      input["results"] = [];

      for (let j = 0; j < timesToPump.length; j++) {
        let pumpedString = input.prefix.map((item, k) => item + input.pump[k].repeat(timesToPump[j])).join('') + input.suffix;

        const startTime = process.hrtime.bigint();

        try {
          const result = await execRegexWithTimeout(regex, pumpedString, 5000); // 5 seconds timeout
          const endTime = process.hrtime.bigint();
          const elapsedTime = Number(endTime - startTime) / 1000000;
          console.log("String Length:", pumpedString.length, "Pumped:", timesToPump[j], "Match:", result.result !== null, "Time:", elapsedTime);
          input["results"].push({
            string_length: pumpedString.length,
            pumped: timesToPump[j],
            time: elapsedTime,
            match: result.result !== null,
            timeout: false,
            error: null
          });
        } catch (error) {
            const endTime = process.hrtime.bigint();
            const elapsedTime = Number(endTime - startTime) / 1000000;
            console.log("Error:", error.message, "String Length:", pumpedString.length, "Pumped:", timesToPump[j], "Match:", false, "Time:", elapsedTime);
            input["results"].push({
              string_length: pumpedString.length,
              pumped: timesToPump[j],
              time: elapsedTime,
              match: false,
              timeout: true,
              error: error.message
            });

            // Optimization: Break out of the loop if the timeout is reached, since the next iterations will also timeout
            break;
        }
      }
    }
  }

  // Optionally dump results to a file
  const fs = require('fs');
  fs.writeFileSync(`./results/${datasetFileName}_results_${experimentName}.json`, JSON.stringify(dataset, null, 2));

  console.log('Experiments completed.');
};

processDataset().catch(error => {
  console.error('Failed to process dataset:', error);
});

