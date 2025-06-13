<?php

$experimentName = getenv('EXPERIMENT_NAME');
$experimentType = $experimentName == "PHP5_6" ? "old" : "new";
$datasetFileName = getenv('DATASET_FILE');
$dataset = json_decode(file_get_contents('./dataset/' . $datasetFileName), true);

function execRegexWithTimeout($pattern, $subject, $timeout) {
    $pid = pcntl_fork();

    if ($pid == -1) {
        throw new Exception('Failed to fork process');
    } elseif ($pid) {
        // Parent process
        $status = null;
        $start = time();
        while ((time() - $start) < $timeout) {
            $pid_wait = pcntl_waitpid($pid, $status, WNOHANG);
            if ($pid_wait == -1 || $pid_wait > 0) {
                break;
            }
            usleep(10000); // 0.01 second sleep
        }

        if ((time() - $start) >= $timeout) {
            posix_kill($pid, SIGKILL);
            pcntl_waitpid($pid, $status); // Cleanup zombie process
            return null;
        }

        if (pcntl_wifexited($status) && pcntl_wexitstatus($status) == 0) {
            return (bool) pcntl_wexitstatus($status);
        } else {
            return false;
        }
    } else {
        // Child process
        $matches = [];
        $result = preg_match($pattern, $subject, $matches);
        exit($result ? 1 : 0);
    }
}

function processDataset() {
    global $dataset, $experimentName, $datasetFileName;
    $timesToPump = [1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10**4, 25000, 10**5];

    foreach ($dataset as $i => &$data) {
        echo "[" . ($i + 1) . "/" . count($dataset) . "] " . $data['regex'] . " is under test...\n";

        // Ensure a full match
        $pattern = (substr($data['regex'], 0, 1) === '^' ? '' : '^') . $data['regex'] . (substr($data['regex'], -1) === '$' ? '' : '$');
        // Insert delimiters
        $regex = chr(1) . $pattern . chr(1);

        // Check for valid regex
        if (@preg_match($regex, null) === false) {
            if (preg_last_error() !== PREG_NO_ERROR) {
                echo "Unsupported regex pattern: " . $data['regex'] . "\n";
                continue;
            }
        }

        foreach ($data['inputs'] as &$input) {
            echo "Running on: " . json_encode($input) . "\n";
            $input['results'] = [];

            // Pump the string
            foreach ($timesToPump as $j) {
                $pumpedString = implode('', array_map(function ($item, $k) use ($input, $j) {
                    return $item . str_repeat($input['pump'][$k], $j);
                }, $input['prefix'], array_keys($input['prefix']))) . $input['suffix'];

                $startTime = microtime(true);

                $result = execRegexWithTimeout($regex, $pumpedString, 5);

                if ($result === null) {
                    $endTime = microtime(true);
                    $elapsedTime = ($endTime - $startTime) * 1000;

                    echo "Error: " . "Regex operation timed out." . " String Length: " . strlen($pumpedString) . " Pumped: " . $j . " Match: false Time: " . $elapsedTime . "\n";

                    $input['results'][] = [
                        'string_length' => strlen($pumpedString),
                        'pumped' => $j,
                        'time' => $elapsedTime,
                        'match' => false,
                        'timeout' => true,
                        'error' => "Regex operation timed out."
                    ];

                    // Break out of the loop if the timeout is reached
                    break;
                }
                elseif ($result) {
                    $endTime = microtime(true);
                    $elapsedTime = ($endTime - $startTime) * 1000;

                    echo "String Length: " . strlen($pumpedString) . " Pumped: " . $j . " Match: " . 1 . " Time: " . $elapsedTime . "\n";

                    $input['results'][] = [
                        'string_length' => strlen($pumpedString),
                        'pumped' => $j,
                        'time' => $elapsedTime,
                        'match' => true,
                        'timeout' => false,
                        'error' => null
                    ];
                }
                else {
                    $endTime = microtime(true);
                    $elapsedTime = ($endTime - $startTime) * 1000;

                    echo "String Length: " . strlen($pumpedString) . " Pumped: " . $j . " Match: " . 0 . " Time: " . $elapsedTime . "\n";

                    $input['results'][] = [
                        'string_length' => strlen($pumpedString),
                        'pumped' => $j,
                        'time' => $elapsedTime,
                        'match' => false,
                        'timeout' => false,
                        'error' => null
                    ];
                }
            }
        }
    }

    // Dump results to a file
    file_put_contents("./results/" . $datasetFileName . "_results_" . $experimentName . ".json", json_encode($dataset, JSON_PRETTY_PRINT));

    echo 'Experiments completed.' . "\n";
}

try {
    processDataset();
} catch (Exception $e) {
    echo "Failed to process dataset: " . $e->getMessage() . "\n";
}

?>
