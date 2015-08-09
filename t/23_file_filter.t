#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 7;

use lib '../lib';
use App::ltrash::_file_filter;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Basename';
  use_ok 'Time::Local';
  use_ok 'App::ltrash::_file_type';
  use_ok 'App::ltrash::_get_path';
  use_ok 'App::ltrash::_wildcard_to_regex';
  use_ok 'App::ltrash::_backup_invalid_file';
}

{
  # no more test
  1;
}

