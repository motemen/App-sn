package App::sn::Command::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use Coro;

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

    foreach (@notes) {
        next if $_->{deleted};
        my $head = ($_->{content} || '') =~ /^\s*(.{1,30})/m ? $1 : '';
        print "$_->{key} $head\n";
    }
}

1;
