#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Test::More tests => 5;

use lib '../lib';
use App::ltrash::_get_size;

BEGIN {
  use_ok 'Exporter';
}

{
  my $size;
  $size = _human_readable_size _size_by_byte '1.00M';
  $size =~ s/\s+//g;
  is $size, '1.00M';

  $size = _human_readable_size _size_by_byte '1.00B';
  $size =~ s/\s+//g;
  is $size, '1.00B';

  $size = _human_readable_size _size_by_byte '3.45M';
  $size =~ s/\s+//g;
  is $size, '3.45M';

  $size = _human_readable_size _size_by_byte '99.99T';
  $size =~ s/\s+//g;
  is $size, '99.99T';
}

