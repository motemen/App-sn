package App::sn::List;
use strict;
use warnings;
use parent 'App::CLI::Command';
use App::sn::API;

sub run {
    my ($self, $arg) = @_;
    my $api = App::sn::API->new;

    my $mark; {
        my $res = $api->get(
            'index',
            $mark ? { mark => $mark } : { since => $App::sn::state->{lastmodified} || 0 }
        );
        foreach (@{$res->{data}}) {
            $App::sn::state->{notes}->{ $_->{key} } = $_;
            $App::sn::state->{lastmodified} = $_->{modifydate}
                if $_->{modifydate} > ( $App::sn::state->{lastmodified} || 0);
        }
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
        print "$_->{key}\n";
    }
}

1;
