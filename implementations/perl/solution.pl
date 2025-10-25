#!/usr/bin/env perl
# Perl Concurrent Log Anomaly Counter
# Uses threads for parallel processing (built-in)

use strict;
use warnings;
use threads;
use threads::shared;

# Try to load JSON::PP, fallback to manual JSON generation
my $has_json;
BEGIN {
    $has_json = eval { require JSON::PP; JSON::PP->import(); 1; };
}

sub contains_word {
    my ($line, $word) = @_;
    # Use word boundary regex for accurate matching
    return $line =~ /\b\Q$word\E\b/;
}

sub count_anomalies_in_chunk {
    my ($lines_ref) = @_;
    my $errors = 0;
    my $warnings = 0;

    foreach my $line (@$lines_ref) {
        if (index($line, 'E') != -1 && contains_word($line, 'ERROR')) {
            $errors++;
        }
        elsif (index($line, 'W') != -1 && contains_word($line, 'WARN')) {
            $warnings++;
        }
    }

    return ($errors, $warnings);
}

# Main program
if (@ARGV != 1) {
    print STDERR "Usage: perl solution.pl <logfile>\n";
    exit 1;
}

my $logfile = $ARGV[0];

unless (-e $logfile) {
    print STDERR "Error: File not found: $logfile\n";
    exit 1;
}

# Read all lines
open(my $fh, '<', $logfile) or die "Cannot open file: $!";
my @lines = <$fh>;
close($fh);
chomp @lines;

# Get number of CPUs (simple heuristic)
my $num_cpus = 4; # Default
if (open(my $cpu_fh, '<', '/proc/cpuinfo')) {
    $num_cpus = scalar(grep /^processor/, <$cpu_fh>);
    close($cpu_fh);
} elsif ($^O eq 'darwin') {
    $num_cpus = `sysctl -n hw.ncpu` || 4;
    chomp $num_cpus;
}

my $num_workers = $num_cpus > 0 ? $num_cpus : 4;

# Calculate chunk size
my $total_lines = scalar @lines;
my $chunk_size = int(($total_lines + $num_workers - 1) / $num_workers);

# Create chunks
my @chunks;
for (my $i = 0; $i < $total_lines; $i += $chunk_size) {
    my $end = ($i + $chunk_size - 1 < $total_lines) ? $i + $chunk_size - 1 : $total_lines - 1;
    push @chunks, [@lines[$i..$end]];
}

# Process chunks in parallel using threads
my @threads;
my @results :shared;

foreach my $chunk (@chunks) {
    my $thread = threads->create(sub {
        my ($chunk_ref) = @_;
        return [count_anomalies_in_chunk($chunk_ref)];
    }, $chunk);
    push @threads, $thread;
}

# Collect results
my $total_errors = 0;
my $total_warnings = 0;

foreach my $thread (@threads) {
    my $result = $thread->join();
    $total_errors += $result->[0];
    $total_warnings += $result->[1];
}

# Output JSON result
my $total = $total_errors + $total_warnings;

if ($has_json) {
    my $result = {
        errors => $total_errors,
        warnings => $total_warnings,
        total => $total
    };
    print JSON::PP::encode_json($result), "\n";
} else {
    # Manual JSON generation
    print "{\"errors\": $total_errors, \"warnings\": $total_warnings, \"total\": $total}\n";
}

exit 0;
