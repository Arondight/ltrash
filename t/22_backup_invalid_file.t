#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 6;

use lib '../lib';
use App::ltrash::_backup_invalid_file;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Basename';
  use_ok 'File::Spec';
  use_ok 'File::Copy';
  use_ok 'App::ltrash::_remove_file';
  use_ok 'App::ltrash::_file_deep_copy';
}

{
  # no more test
  1;
}

