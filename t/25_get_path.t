#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 3;

use lib '../lib';
use App::ltrash::_get_path;

BEGIN {
  use_ok 'Exporter';
  use_ok 'Cwd';
  use_ok 'File::Spec';
}

{
  # no more test
  1;
}

