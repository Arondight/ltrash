#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 4;

use lib '../lib';
use App::ltrash::_get_readable_time;

BEGIN {
  use_ok 'Exporter';
  use_ok 'Time::Piece';
  use_ok 'Time::Seconds';
  use_ok 'Time::Local';
}

{
  # no more test
  1;
}

