package App::sn::Command::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use Coro;
use List::Util qw(max);
use List::MoreUtils qw(first_value);

use constant options => (
    'no-data' => 'no_data',
);

sub run {
    my ($self, $arg) = @_;

    my $app = $self->app;
    my $mark; {
        my $res = $app->api->get(
            'index',
            $mark ? { mark => $mark } :
            $app->local_data->{last_modified} ? { since => $app->local_data->{last_modified} } : {}
        );

        my @jobs;
        foreach my $note (@{$res->{data}}) {
            $app->local_data->{last_modified} = $note->{modifydate}
                if $note->{modifydate} > ( $app->local_data->{last_modified} || 0);
            
            if ($self->{no_data}) {
                $app->local_data->{notes}->{ $note->{key} }->{$_} = $note->{$_} for keys %$note;
            } else {
                push @jobs, async {
                    my $note = $app->api->get("data/$note->{key}");
                    $app->local_data->{notes}->{ $note->{key} } = $note;
                };
            }
        }
        $_->join for @jobs;

        redo if $mark = $res->{mark};
    }

    my @notes = map {
        $_->[0]
    } sort {
        $b->[1] <=> $a->[1]
    } map {
        [ $_, $_->{modifydate} ]
    } values %{ $app->local_data->{notes} };

    my %key = map { ( $_->{key} => $_->{key} ) } @notes;
    if (eval { require Algorithm::UniqueSubstring; 1 }) {
        my $subkeys = Algorithm::UniqueSubstring::unique_substrings(map { $_->{key} } @notes);
        foreach (keys %$subkeys) {
            if (my $subkey = first_value { /^\w/ } @{ $subkeys->{$_} }) {
                $key{$_} = $subkey;
            }
        }
    }

    my $n = max map { length $_ } values %key;
    foreach (@notes) {
        next if $_->{deleted};
        my $head = ($_->{content} || '') =~ /^\s*(.{1,30})/m ? $1 : '';
        printf "%-${n}s: %s\n", $key{ $_->{key} }, $head;
    }
}

1;

__END__

=head1 NAME

App::sn::Command::List - list notes

=head1 USAGE

sn.pl list

=head1 OPTIONS

    --no-data

=cut
