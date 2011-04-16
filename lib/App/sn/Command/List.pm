package App::sn::Command::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use App::sn::API;
use Coro;

sub run {
    my ($self, $arg) = @_;
    my $api = App::sn::API->new;

    my $mark; {
        my $res = $api->get(
            'index',
            $mark ? { mark => $mark } : { since => $App::sn::state->{lastmodified} || 0 }
        );

        my @jobs;
        foreach my $note (@{$res->{data}}) {
            $App::sn::state->{lastmodified} = $note->{modifydate}
                if $note->{modifydate} > ( $App::sn::state->{lastmodified} || 0);
            push @jobs, async {
                my $note = $api->get_async("data/$note->{key}");
                $App::sn::state->{notes}->{ $note->{key} } = $note;
            };
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
    } values %{ $App::sn::state->{notes} };

    foreach (@notes) {
        next if $_->{deleted};
        my ($head) = $_->{content} =~ /^\s*(.{1,30})/m;
        print "$_->{key} $head\n";
    }
}

1;
