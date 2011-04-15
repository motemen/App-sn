package App::sn::New;
use strict;
use warnings;
use parent 'App::sn::Edit';

sub run {
    my ($self) = @_;

    $self->init(undef);
    $self->edit;
}

1;
