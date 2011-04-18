#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use App::sn::Command;

$|++;
binmode STDOUT, ':utf8';

@ARGV = ('help') unless @ARGV;

App::sn::Command->dispatch;
