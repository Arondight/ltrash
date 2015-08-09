# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_get_matching_file;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use File::Basename;

our @EXPORT = qw {
  _get_matching_file
};

use subs qw {
  _get_matching_file
};

# ============================================
# 获得所有符合正则表达式期望的文件名
#
# 参数:
# 带绝对路径的待匹配串
# ============================================
sub _get_matching_file ($) {
  my $file = shift;
  my %file_list = ();   # 利用散列key 唯一性过滤重复文件
  my ($path, $keyword) = ( (dirname $file), (basename $file) );

  opendir my $dir_fh, $path
    or die "EE: 无法打开目录$path。";

  for my $file (readdir $dir_fh) {
    next
      if $file =~ /^\.{1,2}$/o;

    $file_list{$file} = 1
      if $file =~ /$keyword/;
  }

  close $dir_fh;

  return keys %file_list;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_get_matching_file

=head1 描述

获得所有符合正则表达式期望的文件名

=head1 用法

  use App::ltrash::_get_matching_file;

  my $to_match = '/path/to/file.+name';

  my @files = _get_matching_file $to_match;

=cut

