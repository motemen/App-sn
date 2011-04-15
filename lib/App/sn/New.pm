package App::sn::New;
use strict;
use warnings;
use autodie;
use parent 'App::CLI::Command';
use File::Temp qw(tempdir tempfile);
use App::sn::API;
use Filesys::Notify::Simple;
use File::Basename qw(basename);
use Encode;

sub run {
    my ($self, $arg) = @_;
    $self->{api} = App::sn::API->new;
    $self->{key} = undef;
    $self->{content} = '';
    $self->{modifydate} = undef;
    $self->{version} = undef;
    $self->{syncnum} = undef;

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(DIR => $dir);

    $self->{filename} = $filename;

    if (my $pid = fork()) {
        local $SIG{CHLD} = sub {
            exit 0;
        };
        local $SIG{__DIE__} = sub {
            kill 9, $pid;
            die @_;
        };
        my $watcher = Filesys::Notify::Simple->new([ $dir ]);
        $watcher->wait(sub {
            foreach (@_) {
                next unless basename($_->{path}) eq basename($filename);
                open my $in, '<', $filename;
                my $content = decode_utf8 do { local $/; <$in> };
                if ($content ne $self->{content}) {
                    $self->update($content);
                }
            }
        }) while 1;
    } else {
        system $ENV{EDITOR}, $filename;
    }
}

sub update {
    my ($self, $content) = @_;

    my $res;
    if (defined $self->{key}) {
        # update
        $res = $self->{api}->post("data/$self->{key}", { content => $content, version => ++$self->{version}, syncnum => ++$self->{syncnum} });
    } else {
        # create new
        $res = $self->{api}->post('data', { content => $content });
        $self->{version} = $res->{version};
        $self->{syncnum} = $res->{syncnum};
        $self->{key}     = $res->{key};
    }

    $self->{modifydate} = $res->{modifydate};

    if ($self->{version} != $res->{version} || $res->{syncnum} != $self->{syncnum}) {
        my $res = $self->{api}->get("data/$self->{key}");
        $self->{version} = $res->{version};
        $self->{syncnum} = $res->{syncnum};
        $self->{content} = $res->{content};
        if ($self->{content} ne $content) {
            open my $out, '>', $self->{filename};
            print $out $self->{content};
        }
    }

}

1;
