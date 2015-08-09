# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_get_path;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use Cwd qw (getcwd);
use File::Spec;

our @EXPORT = qw {
  _get_pwd_absolute_path
  _get_trash_absolute_path
};

use subs qw {
  _get_pwd_absolute_path
  _get_trash_absolute_path
};

# ============================================
# 获取作为参数的文件名在当前目录下的的绝对路径
#
# 参数:
# $文件名
# ============================================
sub _get_pwd_absolute_path ($) {
  my ($filename, $path) = (shift, );
  my $rootdir = File::Spec->rootdir;
  my $PWD = getcwd;

  $path = $filename;

  SWITCH: {
    # 是一个绝对路径则返回参数本身
    $filename =~ /^$rootdir/ and do {
      last SWITCH;
    };

    # '~' 开头则首先解释'~'，然后返回文件名
    $filename =~ /^~/ and do {
      $path =~ s{^(?:~)(.*)$}{join '', $ENV{HOME}, $1}oe;
      last SWITCH;
    };

    # 其他情况返回当前目录和文件名的连接结果
    DEFAULT: {
      $path = File::Spec->catfile ($PWD, $filename);
    }
  }

  # 去除路径后可能的'/'
  $path =~ s{(.+?)/*$}{$1}o;

  return $path;
}

# ============================================
# 获取作为参数的文件名在回收站目录下的绝对路径
#
# 参数
# \%trash_env
# $路径标记，可以是'info'、'file' 或者'backup'
# $文件名
# ============================================
sub _get_trash_absolute_path ($$$) {
  my $trash_env = shift;
  my ($type, $filename) = (shift, shift);

  SWITCH: {
    $type =~ /info/oi and do {
      return File::Spec->catfile ($trash_env->{TRASH_INFO_PATH}, $filename);
    };

    $type =~ /file/oi and do {
      return File::Spec->catfile ($trash_env->{TRASH_FILE_PATH}, $filename);
    };

    $type =~ /backup/oi and do {
      return File::Spec->catfile ($trash_env->{TRASH_BACKUP_PATH}, $filename);
    };

    DEFAULT: {
      die "DIE: 参数$type 错误。";
    }
  }
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_get_path

=head1 描述

请忘掉这个模块，避免使用它！

=cut

