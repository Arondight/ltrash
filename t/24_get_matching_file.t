#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 2;

use lib '../lib';
use App::ltrash::_get_matching_file;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Basename';
}

{
  # no more test
  1;
}

