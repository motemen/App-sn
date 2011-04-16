package App::sn::Storage;
use strict;
use warnings;
use autodie;
use YAML::XS;
use File::HomeDir;
use File::Spec;

sub file {
    return File::Spec->catfile(File::HomeDir->my_home, '.sn.pl.yaml');
}

sub load {
    my $class = shift;
    my $data = eval {
        open my $fh, '<', $class->file;
        local $/;
        YAML::XS::Load <$fh>;
    } || {};
    return bless { data => $data }, $class;
}

sub save {
    my $self = shift;
    warn 'Storing to ' . $self->file . "\n" if $ENV{DEBUG_SN_PL};
    my $yaml = YAML::XS::Dump $self->{data};
    open my $fh, '>', $self->file;
    print $fh $yaml;
}

sub no_auto_save {
    my $self = shift;
    $self->{no_auto_save}++;
}

sub DESTROY {
    my $self = shift;
    return if $self->{no_auto_save};
    $self->save;
}

1;
