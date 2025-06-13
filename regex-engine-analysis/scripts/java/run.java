import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;
import org.json.*;

public class run {

    private static String experimentName = System.getenv("EXPERIMENT_NAME");
    private static String experimentType = "Java8".equals(experimentName) ? "old" : "new";
    private static String datasetFileName = System.getenv("DATASET_FILE");
    private static JSONArray dataset;

    static {
        try {
            String content = new String(Files.readAllBytes(Paths.get("./dataset/" + datasetFileName)));
            dataset = new JSONArray(content);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static Map<String, Object> execRegexWithTimeout(Pattern regex, String input, int timeout) throws TimeoutException, InterruptedException, ExecutionException {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Callable<Boolean> task = () -> regex.matcher(input).matches();
        Future<Boolean> future = executor.submit(task);

        try {
            Boolean match = future.get(timeout, TimeUnit.SECONDS);
            Map<String, Object> result = new HashMap<>();
            result.put("result", match);
            return result;
        } catch (TimeoutException e) {
            throw new TimeoutException("Regex operation timed out.");
        } finally {
            executor.shutdown();
        }
    }

    private static void processDataset() {
        int[] timesToPump = {1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, (int) Math.pow(10, 4), 25000, (int) Math.pow(10, 5), (int) Math.pow(10, 6)};

        for (int i = 0; i < dataset.length(); i++) {
            JSONObject data = dataset.getJSONObject(i);
            System.out.printf("[%d/%d] %s%n", i + 1, dataset.length(), data.getString("regex"));

            // Ensure a full match
            String regexPattern = (!data.getString("regex").startsWith("^") ? "^" : "") + data.getString("regex") + (!data.getString("regex").endsWith("$") ? "$" : "");

            // Check if the regex is valid
            Pattern regex;
            try {
                regex = Pattern.compile(regexPattern);
            } catch (PatternSyntaxException e) {
                System.out.println("Unsupported regex pattern: " + regexPattern);
                continue;
            }

            JSONArray inputs = data.getJSONArray("inputs");

            for (Object obj : inputs) {
                JSONObject input = (JSONObject) obj;
                // print the input
                System.out.println("Running on: " + input.toString());

                JSONArray inputResults = new JSONArray();
                input.put("results", inputResults);

                for (int j : timesToPump) {
                    StringBuilder pumpedString = new StringBuilder();
                    JSONArray prefix = input.getJSONArray("prefix");
                    JSONArray pump = input.getJSONArray("pump");

                    for (int k = 0; k < prefix.length(); k++) {
                        pumpedString.append(prefix.getString(k));

                        String pumpString = pump.getString(k);
                        for (int repeat = 0; repeat < j; repeat++) {
                            pumpedString.append(pumpString);
                        }
                    }
                    pumpedString.append(input.getString("suffix"));

                    long startTime = System.currentTimeMillis();
                    try {
                        boolean success = (boolean) execRegexWithTimeout(regex, pumpedString.toString(), 5).get("result");
                        long elapsedTime = System.currentTimeMillis() - startTime;
                        System.out.printf("String Length: %d Pumped: %d Match: %b Time: %f%n", pumpedString.length(), j, success, (double) elapsedTime);

                        JSONObject resultData = new JSONObject()
                                .put("string_length", pumpedString.length())
                                .put("pumped", j)
                                .put("time", elapsedTime)
                                .put("match", success)
                                .put("timeout", false)
                                .put("error", JSONObject.NULL);

                        inputResults.put(resultData);
                    } catch (Exception ex) {
                        long elapsedTime = System.currentTimeMillis() - startTime;
                        System.out.printf("Error: %s String Length: %d Pumped: %d Match: false Time: %f%n", ex.getMessage(), pumpedString.length(), j, (double) elapsedTime);

                        JSONObject resultData = new JSONObject()
                                .put("string_length", pumpedString.length())
                                .put("pumped", j)
                                .put("time", elapsedTime)
                                .put("match", false)
                                .put("timeout", true)
                                .put("error", ex.getMessage());

                        inputResults.put(resultData);

                        break;
                    }
                }

            }
        }

        // Dump results to a file
        try (FileWriter file = new FileWriter("./results/" + datasetFileName + "_results_" + experimentName + ".json")) {
            file.write(dataset.toString(2));
        } catch (IOException e) {
            System.err.println("Error writing results to file.");
        }

        System.out.println("Experiments completed.");
        System.exit(0);
    }

    public static void main(String[] args) {
        try {
            processDataset();
        } catch (Exception e) {
            System.out.println("Failed to process dataset: " + e.getMessage());
        }
    }
}
