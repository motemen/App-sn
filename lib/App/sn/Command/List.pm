package App::sn::Command::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use Coro;
use List::Util qw(max);
use List::MoreUtils qw(any first_value);
use Term::ANSIColor;
use Encode;

use constant options => (
    'no-data'  => 'no_data',
    'tag|t=s@' => 'tags',
);

sub run {
    my ($self, $arg) = @_;

    my $app = $self->app;
    my $mark; {
        my $index = $app->api->get(
            'index',
            $mark ? { mark => $mark } :
            $app->local_data->{last_modified} ? { since => $app->local_data->{last_modified} } : {}
        );

        my @jobs;
        foreach my $note (@{ $index->{data} }) {
            $app->local_data->{last_modified} = $note->{modifydate}
                if $note->{modifydate} > ( $app->local_data->{last_modified} || 0);
            
            if ($self->{no_data}) {
                $app->local_data->{notes}->{ $note->{key} }->{$_} = $note->{$_} for keys %$note;
            } else {
                push @jobs, async {
                    print STDERR "Fetching note $note->{key}\n";
                    my $note = $app->api->get("data/$note->{key}");
                    $app->local_data->{notes}->{ $note->{key} } = $note;
                };
            }
        }
        $_->join for @jobs;

        redo if $mark = $index->{mark};
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

    my %filter_tags = map { decode_utf8($_) => 1 } @{ $self->{tags} || [] };

    my $w = max map { length $_ } values %key;
    foreach my $note (@notes) {
        my @tags = @{ $note->{tags} || [] };
        next if $note->{deleted};
        if (%filter_tags) {
            next unless any { $filter_tags{$_} } @tags;
        }
        my $head = ($note->{content} || '') =~ /^\s*(.{1,30})/m ? $1 : '';
        print colored [ 'yellow' ], sprintf "%${w}s", $key{ $note->{key} };
        print ' ';
        print $head;
        if (@tags) {
            print '  ';
            print join ' ', map { colored [ 'blue' ], $_ } @tags;
        }
        print "\n";
    }
}

1;

__END__

=head1 NAME

App::sn::Command::List - list notes

=head1 USAGE

sn.pl list

=head1 OPTIONS

  --no-data	Do not fetch note content.
  -t, --tag {tag}	Filter notes by tag.

=cut
