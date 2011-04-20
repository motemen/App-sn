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

    my $growl = Growl::Any->new(appname => 'sn.pl', events => [ 'Note created', 'Note updated' ]);

    return bless {
        api_root => 'https://simple-note.appspot.com',
        config   => $config,
        ua       => $ua,
        growl    => $growl,
    }, $class;
}

sub app { 'App::sn::Command' }

sub token {
    my $self = shift;
    
    return $self->{token} if $self->{token};

    if (my $auth = $self->app->local_data->{auth}) {
        # expire local token in 12 hours
        if ($auth->{time} + 12 * 60 * 60 < time()) {
            $self->expire_local_auth_token;
        } else {
            return $auth->{token};
        }
    }

    return $self->{token} = $self->_build_token;
}

sub expire_local_auth_token {
    my $self = shift;
    delete $self->app->local_data->{auth};
}

sub _build_token {
    my $self = shift;

    my $res = $self->{ua}->post(
        "$self->{api_root}/api/login",
        Content => encode_base64(
            sprintf 'email=%s&password=%s', uri_escape($self->{config}->{email}), uri_escape($self->{config}->{password})
        )
    );
    warn "POST $self->{api_root}/api/login\n" if $ENV{DEBUG_SN_PL};
    die $res->status_line unless $res->is_success;
    my $token = $res->content;
    $self->app->local_data->{auth} = {
        time => time(),
        token => $token,
    };
    return $token;
}

sub get {
    my ($self, $path, $params) = @_;
    my $url = URI->new("$self->{api_root}/api2/$path");
    $url->query_form(
        email => $self->{config}->{email},
        auth  => $self->token,
        %$params
    );
    warn "GET $url\n" if $ENV{DEBUG_SN_PL};
    my $res = $self->{ua}->get($url);
    warn "GET $url => " . $res->code . "\n" if $ENV{DEBUG_SN_PL};
    if ($res->code eq '401' && !$self->{auth_retry}) {
        $self->{auth_retry}++;
        $self->expire_local_auth_token;
        return &get;
    }
    die $res->status_line if $res->is_error;
    return decode_json $res->content;
}

sub post {
    my ($self, $path, $data) = @_;
    warn "POST $self->{api_root}/api2/$path\n" if $ENV{DEBUG_SN_PL};
    my $res = $self->{ua}->post(
        sprintf("$self->{api_root}/api2/$path?auth=%s&email=%s", uri_escape($self->token), uri_escape($self->{config}->{email})),
        Content => encode_json($data),
    );
    warn "POST $self->{api_root}/api2/$path => " . $res->code . "\n" if $ENV{DEBUG_SN_PL};
    if ($res->code eq '401' && $self->{auth_retry}) {
        $self->{auth_retry}++;
        $self->expire_local_auth_token;
        return &post;
    }
    die $res->status_line if $res->is_error;
    return decode_json $res->content;
}

sub notify {
    my ($self, $event, $title, $message, $icon) = @_;
    $self->{growl}->notify($event, $title, $message, $icon);
}

1;
