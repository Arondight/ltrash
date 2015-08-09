#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More tests => 3;

use lib '../lib';
use App::ltrash::_file_type;

BEGIN {
  use_ok 'Exporter';
}

{
  is _file_type ('/dev/null'), '字符';
  is _file_type (File::Spec->rel2abs (__FILE__)), '脚本';
}

