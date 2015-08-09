#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Test::More tests => 4;

use lib '../lib';
use App::ltrash::_url_encode;

BEGIN {
  use_ok 'Exporter';
}

{
  is _url_encode 'こんにちは',
      "\U%e3%81%93%e3%82%93%e3%81%ab%e3%81%a1%e3%81%af\E";

  is _url_decode '%e4%bd%a0%e5%a5%bd',
      '你好';

  is _url_decode _url_encode 'http://千变万化还是你.html',
      'http://千变万化还是你.html';

}

