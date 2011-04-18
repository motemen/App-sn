package App::sn::Command::Cat;
use strict;
use warnings;
use parent 'App::CLI::Command';

use constant options => (
    'local|l' => 'local',
);

sub run {
    my ($self, $key) = @_;

    if (defined $key) {
        if (my @possible_keys = grep /\Q$key\E/, keys %{$self->app->local_data->{notes}}) {
            if (@possible_keys == 1) {
                $key = $possible_keys[0];
            } elsif (@possible_keys > 1) {
                die join("\n", qq(Note key '$key' specifies multiple keys:), map " * $_", @possible_keys) . "\n";
            }
        }
    } else {
        $self->usage;
        exit 1;
    }

    my $note = $self->{local} ? $self->app->local_data->{notes}->{$key} : $self->app->api->get("data/$key");
    print $note->{content};
}

1;

__END__

=head1 NAME

App::sn::Command::Cat - print note content to stdout

=head1 USAGE

sn.pl cat [--local] {note-key}

=head1 OPTIONS

  --local, -l	Print local data.

=cut
