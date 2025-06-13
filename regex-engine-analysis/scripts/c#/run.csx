#r "nuget: System.Text.Json"
#r "nuget: System.Text.RegularExpressions"
#r "nuget: Newtonsoft.Json"

using System;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

// Global variables
var experimentName = Environment.GetEnvironmentVariable("EXPERIMENT_NAME");
var experimentType = experimentName == "NetV6_0_420" ? "old" : "new";
var regexOption = Enum.IsDefined(typeof(RegexOptions), "NonBacktracking") ? (RegexOptions)Enum.Parse(typeof(RegexOptions), "NonBacktracking") : RegexOptions.None;

// Read and parse the dataset
var datasetFileName = Environment.GetEnvironmentVariable("DATASET_FILE");
var datasetJson = File.ReadAllText("./dataset/" + datasetFileName);
var dataset = JsonConvert.DeserializeObject<List<JObject>>(datasetJson);

// Helper function to execute regex with timeout
bool ExecRegexWithTimeout(string pattern, string input, int timeoutMs, out Match match)
{
    try
    {
        try
        {
            var regex = new Regex(pattern, regexOption, TimeSpan.FromMilliseconds(timeoutMs));
            match = regex.Match(input);
            return match.Success;
        }
        catch (ArgumentException ex)
        {
            Console.WriteLine($"Unsupported regex pattern: {pattern}");
            throw new ArgumentException($"Invalid regex pattern: {ex.Message}");
        }
        catch (NotSupportedException ex)
        {
            Console.WriteLine($"Not supported regex: {pattern}");
            throw new NotSupportedException($"Not supported regex: {ex.Message}");
        }
    }
    catch (RegexMatchTimeoutException)
    {
        throw new TimeoutException("Regex operation timed out.");
    }
}

// Main function to process the dataset
void ProcessDataset()
{
    var timesToPump = new int[] { 1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, (int)Math.Pow(10, 4), 25000, (int)Math.Pow(10, 5), (int)Math.Pow(10, 6) };

    for (int i = 0; i < dataset.Count; i++)
    {
        var data = dataset[i];
        Console.WriteLine($"[{i + 1}/{dataset.Count}] {data["regex"]}");

        // Ensure a full match
        string regexPattern = (data["regex"].ToString().StartsWith("^") ? "" : "^") + data["regex"].ToString() + (data["regex"].ToString().EndsWith("$") ? "" : "$");
        data["regex"] = regexPattern;

        var inputs = data["inputs"] as JArray;

        foreach (var input in inputs)
        {
            Console.WriteLine($"Running on: {JsonConvert.SerializeObject(input, Formatting.Indented)}");
            var inputResults = new JArray();
            input["results"] = inputResults;

            foreach (var j in timesToPump)
            {
                var pumpedString = new StringBuilder();

                for (int k = 0; k < input["prefix"].Count(); k++)
                {
                    pumpedString.Append(input["prefix"][k]);
                    pumpedString.Append(new StringBuilder().Insert(0, input["pump"][k].ToString(), j).ToString());
                }
                pumpedString.Append(input["suffix"]);

                var stopwatch = System.Diagnostics.Stopwatch.StartNew();

                try
                {
                    Match match;
                    bool success = ExecRegexWithTimeout(data["regex"].ToString(), pumpedString.ToString(), 5000, out match);
                    stopwatch.Stop();
                    var elapsedTime = stopwatch.Elapsed.TotalMilliseconds;
                    Console.WriteLine($"String Length: {pumpedString.Length} Pumped: {j} Match: {success} Time: {elapsedTime}");

                    var resultData = new JObject
                    {
                        { "string_length", pumpedString.Length },
                        { "pumped", j },
                        { "time", elapsedTime },
                        { "match", success },
                        { "timeout", false },
                        { "error", null }
                    };

                    inputResults.Add(resultData);
                }
                catch(ArgumentException ex)
                {
                    continue;
                }
                catch(NotSupportedException ex)
                {
                    continue;
                }
                catch (TimeoutException ex)
                {
                    stopwatch.Stop();
                    var elapsedTime = stopwatch.Elapsed.TotalMilliseconds;
                    Console.WriteLine($"Error: {ex.Message} String Length: {pumpedString.Length} Pumped: {j} Match: false Time: {elapsedTime}");

                    var resultData = new JObject
                    {
                        { "string_length", pumpedString.Length },
                        { "pumped", j },
                        { "time", elapsedTime },
                        { "match", false },
                        { "timeout", true },
                        { "error", ex.Message }
                    };

                    inputResults.Add(resultData);

                    // Optimization: Break out of the loop if the timeout is reached, since the next iterations will also timeout
                    break;
                }
            }
        }
    }

    // Dump results to a file
    var resultsJson = JsonConvert.SerializeObject(dataset, Formatting.Indented);
    File.WriteAllText($"./results/{Path.GetFileNameWithoutExtension(datasetFileName)}_results_{experimentName}.json", resultsJson);

    Console.WriteLine("Experiments completed.");
}

// Main script execution
try
{
    ProcessDataset();
}
catch (Exception ex)
{
    Console.WriteLine($"Failed to process dataset: {ex.Message}");
}
