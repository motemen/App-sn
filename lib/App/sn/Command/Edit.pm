package App::sn::Command::Edit;
use strict;
use warnings;
use autodie;
use parent 'App::CLI::Command';
use autodie;
use File::Temp qw(tempdir tempfile);
use Filesys::Notify::Simple;
use File::Basename qw(basename dirname);
use Encode;

use constant options => (
    'help' => 'help',
);

sub run {
    my ($self, $key) = @_;

    $self->init($key);
    $self->edit;
}

sub init {
    my ($self, $key) = @_;

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
        # local $SIG{CHLD} = sub {
        #     wait;
        #     exit 0;
        # };
        local $SIG{HUP} = sub {
            wait;
            $self->update_if_changed;
            exit 0;
        };
        local $SIG{__DIE__} = sub {
            kill KILL => $pid;
            $self->update_if_changed;
            die @_;
        };
        my $watcher = Filesys::Notify::Simple->new([ dirname($self->{filename}) ]);
        $watcher->wait(sub {
            foreach (@_) {
                next unless basename($_->{path}) eq basename($self->{filename});
                $self->update_if_changed;
            }
        }) while 1;
    } else {
        $self->app->storage->no_auto_save;
        system $ENV{EDITOR}, $self->{filename};
        kill HUP => getppid();
    }
}

sub update {
    my ($self, $content) = @_;

    my $res;
    if (defined $self->{key}) {
        # update
        $res = $self->app->api->post("data/$self->{key}", { content => $content, version => ++$self->{version}, syncnum => ++$self->{syncnum} });
        $self->app->api->notify(
            'Note updated', 'Note updated',
            $self->_note_head($content),
            'http://simple-note.appspot.com/img/logo.png'
        );
    } else {
        # create new
        $res = $self->app->api->post('data', { content => $content });
        $self->{version} = $res->{version};
        $self->{syncnum} = $res->{syncnum};
        $self->{key}     = $res->{key};
        $self->app->api->notify(
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

sub update_if_changed {
    my $self = shift;
    my $content = $self->file_content;
    if ($content ne $self->{content}) {
        $self->update($content);
    }
}

sub download {
    my $self = shift;
    my $note = $self->app->api->get("data/$self->{key}");
    $self->{version} = $note->{version};
    $self->{syncnum} = $note->{syncnum};
    $self->{content} = $note->{content};
    open my $out, '>', $self->{filename};
    print $out $self->{content};
    $self->app->local_data->{notes}->{ $note->{key} } = $note;
}

sub file_content {
    my $self = shift;
    open my $in, '<', $self->{filename};
    return decode_utf8 do { local $/; <$in> };
}

sub _note_head {
    my ($self, $content) = @_;
    my ($head) = $content =~ /^\s*(.+)$/m;
    return $head;
}

1;

__END__

=head1 NAME

App::sn::Command::Edit - edit note

=head1 USAGE

sn.pl edit {note_key}

=cut
