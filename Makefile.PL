use inc::Module::Install;

name 'App-sn';
all_from 'lib/App/sn.pm';

requires 'autodie';
requires 'parent';
requires 'File::Temp';
requires 'Filesys::Notify::Simple';
requires 'File::Basename';
requires 'Encode';
requires 'Config::Pit';
requires 'URI';
requires 'URI::Escape';
requires 'JSON::XS';
requires 'MIME::Base64';
requires 'LWP::UserAgent';
requires 'Script::State';

auto_set_repository;
auto_include;

WriteAll;
