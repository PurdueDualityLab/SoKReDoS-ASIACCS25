use strict;
use warnings;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(strftime);
use Data::Dumper;
use utf8;
use open ':std', ':encoding(UTF-8)';
binmode STDOUT, ":utf8";

$| = 1; # Auto-flush STDOUT

my $experiment_name = $ENV{'EXPERIMENT_NAME'};
my $experiment_type = $experiment_name eq "PerlV5_38_2" ? "new" : "old";

my $dataset_file = $ENV{'DATASET_FILE'};
open my $fh, '<', "./dataset/$dataset_file" or die "Cannot open dataset file: $!";
my $json_text = do { local $/; <$fh> };
my $dataset = decode_json($json_text);
close $fh;

sub match {
    my ($string, $regex, $timeout_secs) = @_;

    my $pid = fork();
    die "can't fork: $!" if !defined $pid;

    if ($pid == 0) {
        # child process
        $SIG{ALRM} = 'DEFAULT';
        alarm $timeout_secs;

        exit(($string =~ $regex) ? 0 : 1);
    }

    # parent process
    waitpid($pid, 0);

    die "regex timed out\n" if $? & 0x7f;
    return !($? >> 8);
}

sub exec_regex_with_timeout {
    my ($regex, $input, $timeout) = @_;
    my $result;

    eval {
        if (match($input, $regex, $timeout)) {
            $result = { result => 1 };
        } else {
            $result = { result => 0 };
        }
    };

    if ($@) {
        die 'Regex operation timed out.' if $@ =~ /regex timed out/;
        die $@;
    }
    return $result;
}

sub process_dataset {
    my @times_to_pump = (1, 10, 25, 50, 100, 150, 200, 250, 500, 1000, 2500, 5000, 10**4, 25000, 10**5, 10**6);

    for my $i (0 .. @$dataset - 1) {
        my $data = $dataset->[$i];
        print "[" . ($i + 1) . "/" . scalar(@$dataset) . "] " . $data->{'regex'} . " is under test...\n";

        my $pattern = ($data->{'regex'} =~ /^\^/ ? '' : '^') . $data->{'regex'} . ($data->{'regex'} =~ /\$$/ ? '' : '$');

        my $regex;
        eval {
            $regex = qr/$pattern/;
        };
        if ($@) {
            print "Unsupported regex pattern: $pattern\n";
            next;
        }

        for my $input (@{$data->{'inputs'}}) {
            print "Running on: " . Dumper($input);

            $input->{"results"} = [];

            for my $j (@times_to_pump) {
                my $pumped_string = join('', map { $input->{'prefix'}[$_] . $input->{'pump'}[$_] x $j } 0 .. $#{$input->{'prefix'}}) . $input->{'suffix'};
                my $start_time = [gettimeofday];

                eval {
                    my $result = exec_regex_with_timeout($regex, $pumped_string, 5); # 5 seconds timeout
                    my $end_time = [gettimeofday];
                    my $elapsed_time = tv_interval($start_time, $end_time) * 1000;
                    print "String Length: " . length($pumped_string) . " Pumped: $j Match: " . ($result->{result} ? 'true' : 'false') . " Time: $elapsed_time\n";
                    push @{$input->{"results"}}, {
                        string_length => length($pumped_string),
                        pumped => $j,
                        time => $elapsed_time,
                        match => $result->{result} ? 1 : 0,
                        timeout => 0,
                        error => undef
                    };
                };
                if ($@) {
                    my $end_time = [gettimeofday];
                    my $elapsed_time = tv_interval($start_time, $end_time) * 1000;
                    print "Error: $@ String Length: " . length($pumped_string) . " Pumped: $j Match: false Time: $elapsed_time\n";
                    push @{$input->{"results"}}, {
                        string_length => length($pumped_string),
                        pumped => $j,
                        time => $elapsed_time,
                        match => 0,
                        timeout => 1,
                        error => $@
                    };

                    # Optimization: Break out of the loop if the timeout is reached, since the next iterations will also timeout
                    last;
                }
            }
        }
    }

    # Optionally dump results to a file
    open my $out_fh, '>', "./results/${dataset_file}_results_${experiment_name}.json" or die "Cannot open results file: $!";
    print $out_fh to_json($dataset, { pretty => 1 });
    close $out_fh;

    print "Experiments completed.\n";
}

eval {
    process_dataset();
};
if ($@) {
    print "Failed to process dataset: $@\n";
}
