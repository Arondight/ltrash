# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_remove_file;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use File::Spec;
use File::Path qw (rmtree);

our @EXPORT = qw {
  _remove_file_recursively
  _remove_sub_file_recursively
};

use subs qw {
  _remove_file_recursively
  _remove_sub_file_recursively
};

# ============================================
# 递归删除普通文件或者目录文件
#
# 参数:
# @文件或目录绝对路径列表
# ============================================
sub _remove_file_recursively (@) {
  for my $file (@_) {
    unless (-e $file or -l $file) {
      say STDERR "WW: 文件\"$file\" 不存在，跳过。";
      next;
    }

    if (-d $file) {
      rmtree $file;
    } else {
      unlink $file;
    }
  }

  return 1;
}

# ============================================
# 删除目录下所有的子文件（保留目录本身）
#
# 参数:
# @目录列表
# ============================================
sub _remove_sub_file_recursively (@) {
  for my $path (@_) {
    unless (-e $path) {
      say STDERR "WW: 目录\"$path\" 不存在，跳过。";
      next;
    }

    eval {
      # 获得所有子文件
      opendir my $path_fh, $path
        or die "EE: 无法打开目录\"$path\"";

      # 递归删除这些子文件
      for my $file (readdir $path_fh) {
        _remove_file_recursively (
          File::Spec->catfile ($path, $file))
          unless $file =~ /^\.{1,2}$/o;
      }

      closedir $path_fh;
    };
    if ($@) {
      say STDERR "\nWW: 清空目录遇到错误，跳过。\n";
      next;
    }
  }

  return 1;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_remove_file

=head1 描述

删除目录或文件

=head1 用法

  use App::ltrash::_remove_file;

  my $path = '/path';
  my $path2 = '/path2';
  my $file = '/path/to/file';

  # 删除$path 和$path 的所有子文件
  _remove_file_recursively $path;

  # 删除$$path2 的所有子文件但保留$path2
  _remove_sub_file_recursively $path2;

  # 删除非目录文件$file
  _remove_file_recursively $file;

=cut

