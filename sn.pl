#!/usr/bin/env perl
use strict;
use warnings;
no  warnings 'once';
use lib 'lib';
use App::sn::Command;

$|++;
binmode STDOUT, ':utf8';

App::sn::Command->dispatch;

# App::sn::Command->storage->save;
