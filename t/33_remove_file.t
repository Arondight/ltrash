#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 3;

use lib '../lib';
use App::ltrash::_remove_file;

BEGIN {
  use_ok 'Exporter';
  use_ok 'File::Spec';
  use_ok 'File::Path';
}

{
  # no more test
  1;
}

