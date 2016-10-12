#!/usr/bin/env perl
#
#
#
use strict;
use warnings;
use Chart::Gnuplot;

# Data
my @xy = ([1.1,-3],[1.2,-2],[3.5,0],[1.4,-6],[5.2,-5.6],[1.5,-6],[1.3,-5]);

my $chart = Chart::Gnuplot->new(
    output => "points.ps"
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    points => \@xy
);

$chart->plot2d($dataSet);
