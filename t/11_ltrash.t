#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Test::More tests => 22;

use lib '../lib';
use App::ltrash;

BEGIN {
  use_ok 'Env';
  use_ok 'FileHandle';
  use_ok 'File::Basename';
  use_ok 'File::Spec';
  use_ok 'File::Copy';
  use_ok 'File::Glob';
  use_ok 'File::Path';
  use_ok 'File::Copy';
  use_ok 'Getopt::Long';
  use_ok 'App::ltrash::_delete_file';
  use_ok 'App::ltrash::_remove_file';
  use_ok 'App::ltrash::_file_type';
  use_ok 'App::ltrash::_file_filter';
  use_ok 'App::ltrash::_get_size';
  use_ok 'App::ltrash::_get_path';
  use_ok 'App::ltrash::_file_deep_copy';
  use_ok 'App::ltrash::_url_encode';
  use_ok 'App::ltrash::_wildcard_to_regex';
  use_ok 'App::ltrash::_get_readable_time';
  use_ok 'App::ltrash::_get_matching_file';
  use_ok 'App::ltrash::_backup_invalid_file';
  use_ok 'App::ltrash::_print_man';
}

{
  # no more test
  1;
}

