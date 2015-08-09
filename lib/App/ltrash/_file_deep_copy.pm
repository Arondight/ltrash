# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_file_deep_copy;

our $VERSION = '0.11';

use strict;
use warnings;
use 5.010;
use File::Basename;
use File::Spec;
use File::Path qw (mkpath);
use File::Copy qw (cp mv);
use Exporter qw (import);

our @EXPORT = qw {
  _file_deep_copy
  _copy_dir
};

use subs qw {
  _file_deep_copy
  _copy_dir
};

# ============================================
# 复制文件或目录
# 这是一个通用模块
# 由App::ltrash 调用时应该显式禁止$link_follow
#
# 参数：
# $链接跟随标记
# $源目录
# $目标目录
# ============================================
sub _file_deep_copy ($$$) {
  my $link_follow = shift;
  my ($src, $dest) = (shift, shift);

  say STDERR "EE：文件\"$src\" 不存在，跳过。"
    and return
    unless -e $src;

  # do copy
  if (-d $src) {
    _copy_dir $link_follow, $src, $dest;
  } else {
    if (-l $src and 1 == $link_follow) {
      $src = readlink $src;
      say STDERR "EE：链接指向\"$src\" 不存在，跳过"
        and return
        unless -e $src;
    }
    eval {
      cp $src, $dest;
    };
    if ($@) {
      warn $@;
    }
  }
}

# ============================================
# 复制整个目录
# 这是一个通用模块
# 由App::ltrash 调用时应该显式禁止$link_follow
#
# 参数：
# $链接跟随标记
# $源目录
# $目标目录
# ============================================
sub _copy_dir ($$$) {
  my $link_follow = shift;
  my ($src, $dest) = (shift, shift);

  # 去除路径后可能的'/'
  $src =~ s{(.+?)/*$}{$1}o;
  $dest =~ s{(.+?)/*$}{$1}o;

  say STDERR "EE：源路径\"$src\" 不存在或不是目录，跳过。"
    and return
    if ! -d $src or ! -e $src;

  say STDERR "EE：目标路径\"$dest\" 存在但不是目录，跳过。"
    and return
    if ! -d $dest and -e $dest;

  # 现在进行递归复制每个文件
  # 此时目标路径一定是存在且可写的
  my $do_copy;
  $do_copy = sub ($$$) {
    my $link_follow = shift;
    my ($src, $dest) = (shift, shift);
    my @files = ( );

    # 构造真正的目标路径
    my $filename = basename $src;
    if (-e $dest) {
      $dest = File::Spec->catfile ($dest, $filename);
    } else {
      mkpath $dest, 0, 0755
    }

    # 获取目录下的文件
    opendir my $file_fh, $src
      or return;
    @files = grep {
      $_ ne '.' and $_ ne '..';
    } readdir $file_fh;
    close $file_fh;
    @files = map {
      File::Spec->catfile ($src, $_);
    } @files;

    # 递归处理
    for my $file_src (@files) {
      my $filename = basename $file_src;
      my $file_dest = File::Spec->catfile ($dest, $filename);

      # 处理链接文件
      if (-l $file_src and 1 == $link_follow) {
        $file_src = readlink $file_src;
        next
          unless -e $file_src;
      }

      # 处理目录文件
      if (-d $file_src) {
        $do_copy-> ($link_follow, $file_src, $file_dest);
      }

      # 复制文件
      eval {
        cp $file_src, $file_dest;
      };
      if ($@) {
        warn $@;
      }
    }
  };

  $do_copy->($link_follow, $src, $dest);
}

1;

=encoding utf8

=head1 名称

App::ltrash::_file_deep_copy

=head1 说明

复制文件或者整个目录

=head1 用法

  use App::ltrash::_file_deep_copy;

  $src = '/path/to/file';
  $dest = '/path/to/file2';
  $link_follow = 0;

  _file_deep_copy $link_follow, $src, $dest;

=cut

