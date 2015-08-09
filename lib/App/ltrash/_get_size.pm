# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_get_size;

our $VERSION = '0.11';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);

our @EXPORT = qw {
  _size_by_byte
  _human_readable_size
};

use subs qw {
  _size_by_byte
  _human_readable_size
};

# ============================================
# 将高可读性的文件大小转换为以字节为单位的格式
# 返回字节数或者undef（如果未指定）
#
# 参数：
# $可带后缀的文件大小
# ============================================
sub _size_by_byte ($) {
  my $size = shift;
  my @units = qw(Y Z E P T G M K B);
  my $boder = 1024;

  return undef
    unless $size;

  say STDERR "EE：大小字段\"$size\" 中，格式无法识别。"
    and exit 1
    unless $size =~ /^\d*\.?\d+[bkmgtpezy]?$/i;

  $size .= 'B'
    if $size =~ /^\d*\.?\d+$/;

  my $start = 0;
  for (0..@units-1) {
    $start = $_
      and last
      if $size =~ /$units[$_]$/i;
  }

  # 反复乘1024 直到得到字节数
  my $number = $size;
  $number =~ s/^(\d*\.?\d+)\w$/$1/;
  # 直到数组倒数第二个下标，因为最后一个元素代表Byte
  for ($start..@units-1-1) {
    $number *= 1024;
  }

  return $number;
}

# ============================================
# 将以字节为单位的文件大小转换为可读性更高的格式
#
# 参数：
# $文件所占字节数
# ============================================
sub _human_readable_size ($) {
  my $size = shift;
  my @units = qw(B K M G T P E Z Y);
  my $max_level = @units - 1;
  my $level = 0;
  my $boder = 1024;

  die 'EE：空参数。'
    unless defined $size;

  # 反复除1024，直到得到一个可读性较高的数值
  while ($size >= $boder) {
    break
      if $level > $max_level;
    $size /= $boder;
    ++$level;
  }

  # 返回一个可读性较高的格式
  # 右对齐4 位数字、空格、左对齐3 字符单位
  return sprintf "%7s%s", sprintf ("%4.2f", $size), $units[$level];
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_get_size

=head1 描述

在可读性较高的文件大小和字节数之间互换。

转换后可能会丢失精度。

=head1 用法

  use App::ltrash::_get_size;

  my $file = '/path/to/file';

  my $size = -l $file ? (lstat $file)[7] : (stat $file)[7];
  my $readable_size = _human_readable_size $size;

  $readable_size = '3.9M';
  $size = _size_by_byte $readable_size;

=cut

