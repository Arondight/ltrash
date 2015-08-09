# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_url_encode;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);

our @EXPORT = qw {
  _url_decode
  _url_encode
};

use subs qw {
  _url_decode
  _url_encode
};

# ============================================
# URL 编码的编码函数
#
# 参数:
# $待解码串
# ============================================
sub _url_encode ($) {
  my $text = shift;

  $text =~ s{[^\w\-\:\.\@\n\/]}{+sprintf "%%%2.2X", ord $&}oeg;

  return $text;
}

# ============================================
# URL 编码的解码函数
#
# 参数:
# $待解码串
# ============================================
sub _url_decode ($) {
  my $text = shift;

  $text =~ s{%(.{2})}{+pack 'C', hex $1}oeg;

  return $text;
}

1;
=encoding utf-8

=head1 名称

App::ltrash::_url_encode

=head1 描述

对文本进行URL 编码/解码。

=head1 用法

  use App::ltrash::_url_encode;

  my $string = "a string";
  my $encode = _url_encode "a string";
  my $decode = _url_decode $encode;

=cut

