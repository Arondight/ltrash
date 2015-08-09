#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use File::Spec;
use Test::More;

use lib '../lib';
use App::ltrash::_wildcard_to_regex;

BEGIN {
  use_ok 'Exporter';
}

{
  my $testingno = 1;
  my @strings = (
    'A word can create a world',
    '({\.})/?++',
    'http://null.html'
  );

  my $wildcard = '*';
  my ($regex) = _wildcard_to_regex $wildcard;
  map { ok ((/^.*$/) == (/$regex/)); } @strings;
  $testingno += 3;

  $wildcard = '.?*';
  ($regex) = _wildcard_to_regex $wildcard;
  map { ok ((/^\...*$/) == (/$regex/)); } @strings;
  $testingno += 3;

  $wildcard = '?.?h*';
  ($regex) = _wildcard_to_regex $wildcard;
  map { ok ((/^.\...*h$/) == (/$regex/)); } @strings;
  $testingno += 3;

  $wildcard = 'wor?d';
  ($regex) = _wildcard_to_regex $wildcard;
  map { ok ((/^wor.d$/) == (/$regex/)); } @strings;
  $testingno += 3;

  $wildcard = '*wor?d*';
  ($regex) = _wildcard_to_regex $wildcard;
  map { ok ((/^.*wor.d.*$/) == (/$regex/)); } @strings;
  $testingno += 3;

  done_testing $testingno;
}

