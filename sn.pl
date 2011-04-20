#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use App::sn::Command;
use Encode::Locale;

$|++;
binmode STDOUT, ':encoding(console_out)';

@ARGV = ('help') unless @ARGV;

App::sn::Command->dispatch;
