use inc::Module::Install;

name 'App-sn';
all_from 'lib/App/sn.pm';

requires 'autodie';
requires 'parent';
requires 'File::Temp';
requires 'File::Basename';
requires 'File::HomeDir';
requires 'File::Spec';
requires 'Filesys::Notify::Simple';
requires 'Encode';
requires 'Encode::Locale';
requires 'Config::Pit';
requires 'URI';
requires 'URI::Escape';
requires 'JSON::XS';
requires 'YAML::XS';
requires 'MIME::Base64';
requires 'LWP::UserAgent';
requires 'AnyEvent::HTTP::LWP::UserAgent';
requires 'Coro';
requires 'List::Util';
requires 'List::MoreUtils';

install_script 'sn.pl';

auto_include;

WriteAll;
