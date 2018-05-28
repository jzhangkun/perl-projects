#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

use threads;
use threads::shared;
use Thread::Queue;

# Global sharing variable
my %status;
share(%status);

# create the update threads before we read our (large volumes of) data
my @thr; my @queue;
my $workerCnt = 10;
$queue[$workerCnt] = Thread::Queue->new();  # response queue
my $cnt = 0;
while ($cnt < $workerCnt) {
    myDebug(1, "Creating worker thread: $cnt");
    $queue[$cnt] = Thread::Queue->new();
    $thr[$cnt] = threads->create(\&worker, $cnt, $workerCnt);
    $cnt++
}

# start to spread works
for my $i (1..100) {
    my $q = $i % $workerCnt;
    $queue[$q]->enqueue("Task $i");
}

# close working queue
$cnt = 0;
while ($cnt < $workerCnt) {
    $queue[$cnt]->enqueue("xXx");
    $cnt++;
}

# clean work thread
$cnt = 0;
while ($cnt < $workerCnt) {
    my @results = $thr[$cnt]->join();
    myDebug(1, "Worker thread: $cnt, results: " . join(' ', @results));
    $cnt++;
}

print Dumper \%status;
print "Summary works: ", scalar(keys %status), "\n";
exit;

sub worker {
    my $threadCnt = shift;
    my $workerCnt = shift;

    myDebug(1, "I am worker thread: $cnt");
    my $queue = $queue[$threadCnt];
    my $msg;
    MSG: while ($msg = $queue->dequeue()) {
        last MSG if ($msg eq 'xXx');
        myDebug(1, "Working on $msg");
        $status{"Worker $cnt On $msg"}++;
    }

    return "MISSION COMPLETED!";
}


sub myDebug {
    my $debug_level = shift;
    print "@_\n";
}
