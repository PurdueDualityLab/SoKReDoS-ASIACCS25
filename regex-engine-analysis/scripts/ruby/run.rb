require 'json'
require 'timeout'

$experiment_name = ENV['EXPERIMENT_NAME']
$experiment_type = $experiment_name == "RubyV3_1_6" ? "old" : "new"
$dataset_filename = ENV['DATASET_FILE']
$dataset = JSON.parse(File.read('./dataset/' + $dataset_filename))

def exec_regex_with_timeout(regex, input, timeout)
    match = false
    read, write = IO.pipe

    pid = Process.fork do
      read.close
      match = !regex.match(input).nil?
      Marshal.dump(match, write)
      exit!(0) # prevents running at_exit handlers
    end

    begin
      Timeout.timeout(timeout) do
        Process.wait(pid)
        write.close
        match = Marshal.load(read)
      end
    rescue Timeout::Error
      Process.kill('KILL', pid) rescue nil
      raise 'Regex operation timed out.'
    ensure
      read.close unless read.closed?
      write.close unless write.closed?
    end

    return { result: match }
end

def process_dataset
  times_to_pump = [1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10**4, 25000, 10**5, 10**6]

  $dataset.each_with_index do |data, i|
    puts "[#{i + 1}/#{$dataset.length}] #{data['regex']} is under test..."

    # Ensure a full match
    pattern = (data['regex'].start_with?('^') ? '' : '^') + data['regex'] + (data['regex'].end_with?('$') ? '' : '$')

    begin
      regex = Regexp.new(pattern)
    rescue => error
      puts "Unsupported regex pattern: #{pattern}"
      next
    end

    data['inputs'].each do |input|
      puts "Running on: #{input}"

      input["results"] = []

      times_to_pump.each do |j|
        pumped_string = input['prefix'].map.with_index { |item, k| item + input['pump'][k] * j }.join('') + input['suffix']
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          result = exec_regex_with_timeout(regex, pumped_string, 5) # 5 seconds timeout
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          elapsed_time = (end_time - start_time) * 1000
          puts "String Length: #{pumped_string.length} Pumped: #{j} Match: #{result[:result] != nil} Time: #{elapsed_time}"
          input["results"] << {
            string_length: pumped_string.length,
            pumped: j,
            time: elapsed_time,
            match: result[:result],
            timeout: false,
            error: nil
          }
        rescue => error
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          elapsed_time = (end_time - start_time) * 1000
          puts "Error: #{error.message} String Length: #{pumped_string.length} Pumped: #{j} Match: false Time: #{elapsed_time}"
          input["results"] << {
            string_length: pumped_string.length,
            pumped: j,
            time: elapsed_time,
            match: false,
            timeout: true,
            error: error.message
          }

          # Optimization: Break out of the loop if the timeout is reached, since the next iterations will also timeout
          break
        end
      end
    end
  end

  # Dump results to a file
  File.write("./results/#{$dataset_filename}_results_#{$experiment_name}.json", JSON.pretty_generate($dataset))

  puts 'Experiments completed.'
end

begin
  process_dataset
rescue => error
  puts "Failed to process dataset: #{error}"
end
