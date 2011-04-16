package App::sn::Edit;
use strict;
use warnings;
use autodie;
use parent 'App::CLI::Command';
use autodie;
use File::Temp qw(tempdir tempfile);
use App::sn::API;
use Filesys::Notify::Simple;
use File::Basename qw(basename dirname);
use Encode;

sub run {
    my ($self, $key) = @_;

    $self->init($key);
    $self->edit;
}

sub init {
    my ($self, $key) = @_;

    $self->{api} = App::sn::API->new;
    $self->{key} = $key;
    $self->{content} = '';
    $self->{modifydate} = undef;
    $self->{version} = undef;
    $self->{syncnum} = undef;

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(DIR => $dir);

    $self->{filename} = $filename;

    $self->download if defined $key;
}

sub edit {
    my $self = shift;

    if (my $pid = fork()) {
        local $SIG{CHLD} = sub {
            exit 0;
        };
        local $SIG{__DIE__} = sub {
            kill 9, $pid;
            die @_;
        };
        my $watcher = Filesys::Notify::Simple->new([ dirname($self->{filename}) ]);
        $watcher->wait(sub {
            foreach (@_) {
                next unless basename($_->{path}) eq basename($self->{filename});
                open my $in, '<', $self->{filename};
                my $content = decode_utf8 do { local $/; <$in> };
                if ($content ne $self->{content}) {
                    $self->update($content);
                }
            }
        }) while 1;
    } else {
        system $ENV{EDITOR}, $self->{filename};
    }
}

sub update {
    my ($self, $content) = @_;

    my $res;
    if (defined $self->{key}) {
        # update
        $res = $self->{api}->post("data/$self->{key}", { content => $content, version => ++$self->{version}, syncnum => ++$self->{syncnum} });
        $self->{api}->notify(
            'Note updated', 'Note updated',
            $self->_note_head($content),
            'http://simple-note.appspot.com/img/logo.png'
        );
    } else {
        # create new
        $res = $self->{api}->post('data', { content => $content });
        $self->{version} = $res->{version};
        $self->{syncnum} = $res->{syncnum};
        $self->{key}     = $res->{key};
        $self->{api}->notify(
            'Note created', 'Note created',
            $self->_note_head($content),
            'http://simple-note.appspot.com/img/logo.png'
        );
    }

    $self->{modifydate} = $res->{modifydate};

    if ($self->{version} != $res->{version} || $res->{syncnum} != $self->{syncnum}) {
        $self->download;
    }

}

sub download {
    my $self = shift;
    my $res = $self->{api}->get("data/$self->{key}");
    $self->{version} = $res->{version};
    $self->{syncnum} = $res->{syncnum};
    $self->{content} = $res->{content};
    open my $out, '>', $self->{filename};
    print $out $self->{content};
}

sub _note_head {
    my ($self, $content) = @_;
    my ($head) = $content =~ /^\s*(.+)$/m;
    return $head;
}

1;
