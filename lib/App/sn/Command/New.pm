package App::sn::Command::New;
use strict;
use warnings;
use parent 'App::sn::Command::Edit';

sub run {
    my ($self) = @_;

    $self->init(undef);
    $self->edit;
}

1;
