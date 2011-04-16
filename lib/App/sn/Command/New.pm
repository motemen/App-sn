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

__END__

=head1 NAME

App::sn::Command::New - edit new note

=head1 USAGE

sn.pl new

=cut
