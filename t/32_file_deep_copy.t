#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 5;

use lib '../lib';
use App::ltrash::_file_deep_copy;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Basename';
  use_ok 'File::Spec';
  use_ok 'File::Path';
  use_ok 'File::Copy';
}

{
  # no more test
  1;
}

