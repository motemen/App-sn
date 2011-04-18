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
    my $data = eval { YAML::XS::LoadFile $class->file } || {};
    return bless { data => $data }, $class;
}

sub save {
    my $self = shift;
    warn 'Storing to ' . $self->file . "\n" if $ENV{DEBUG_SN_PL};
    YAML::XS::DumpFile $self->file, $self->{data};
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
