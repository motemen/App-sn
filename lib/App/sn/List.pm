package App::sn::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use App::sn::API;

sub run {
    my ($self, $arg) = @_;
    my $api = App::sn::API->new;
}

1;
