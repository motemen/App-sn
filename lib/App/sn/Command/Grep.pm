package App::sn::Command::Grep;
use strict;
use warnings;
use parent 'App::CLI::Command';
use Term::ANSIColor;
use Encode;
use Encode::Locale;

sub run {
    my ($self, $pattern) = @_;

    unless (defined $pattern && length $pattern) {
        $self->usage;
        exit 1;
    }

    $pattern = decode(locale => $pattern);

    while (my ($key, $note) = each %{$self->app->local_data->{notes}}) {
        foreach my $line (split /\n/, $note->{content}) {
            if ($line =~ s/($pattern)/colored [ 'yellow' ], $1/ge) {
                print colored([ 'green' ], $key), ": $line\n";
            }
        }
    }
}

1;

__END__

=head1 NAME

App::sn::Command::Grep - grep note content

=head1 USAGE

sn.pl grep {pattern}

=cut
