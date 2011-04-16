#!/usr/bin/env perl
use strict;
use warnings;
no  warnings 'once';
use lib 'lib';
use App::sn::Command;
use Script::State -datafile => "$ENV{HOME}/.sn.data.pl";

binmode STDOUT, ':utf8';

script_state my $state = {};

$App::sn::state = $state;

App::sn::Command->dispatch;
