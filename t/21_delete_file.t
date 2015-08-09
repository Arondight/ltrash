#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 7;

use lib '../lib';
use App::ltrash::_delete_file;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Basename';
  use_ok 'File::Copy';
  use_ok 'App::ltrash::_get_path';
  use_ok 'App::ltrash::_url_encode';
  use_ok 'App::ltrash::_file_deep_copy';
  use_ok 'App::ltrash::_remove_file';
}

{
  # no more test
  1;
}

