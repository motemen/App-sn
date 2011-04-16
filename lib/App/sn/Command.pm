package App::sn::Command;
use strict;
use warnings;
use parent 'App::CLI';
use App::sn::API;
use App::sn::Storage;

sub api {
    my $class = shift;
    return our $api ||= App::sn::API->new;
}

sub storage {
    my $class = shift;
    return our $storage ||= App::sn::Storage->load;
}

sub local_data {
    my $class = shift;
    return $class->storage->{data};
}

1;

