package App::sn::API;
use strict;
use warnings;
use Config::Pit;
use URI;
use URI::Escape qw(uri_escape);
use JSON::XS;
use MIME::Base64 qw(encode_base64);
use AnyEvent::HTTP::LWP::UserAgent;
use Growl::Any;

sub new {
    my $class = shift;

    my $config = pit_get('simple-note.appspot.com', require => { email => 'email', password => 'password' });

    my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
    $ua->show_progress(1) if $ENV{DEBUG_APP_SN};

    my $growl = Growl::Any->new(appname => 'sn.pl', events => [ 'Note created', 'Note updated' ]);

    return bless {
        api_root  => 'https://simple-note.appspot.com',
        config    => $config,
        ua        => $ua,
        growl     => $growl,
    }, $class;
}

sub token {
    my $self = shift;
    return $self->{token} ||= $self->_build_token;
}

sub _build_token {
    my $self = shift;

    my $res = $self->{ua}->post(
        "$self->{api_root}/api/login",
        Content => encode_base64(
            sprintf 'email=%s&password=%s', uri_escape($self->{config}->{email}), uri_escape($self->{config}->{password})
        )
    );
    die $res->status_line unless $res->is_success;
    return $res->content;
}

sub get {
    my ($self, $path, $params) = @_;
    my $url = URI->new("$self->{api_root}/api2/$path");
    $url->query_form(
        email => $self->{config}->{email},
        auth  => $self->token,
        %$params
    );
    my $res = $self->{ua}->get($url);
    return decode_json $res->content;
}

sub post {
    my ($self, $path, $data) = @_;
    my $res = $self->{ua}->post(
        sprintf("$self->{api_root}/api2/$path?auth=%s&email=%s", uri_escape($self->token), uri_escape($self->{config}->{email})),
        Content => encode_json($data),
    );
    return decode_json $res->content;
}

sub notify {
    my ($self, $event, $title, $message, $icon) = @_;
    $self->{growl}->notify($event, $title, $message, $icon);
}

1;
