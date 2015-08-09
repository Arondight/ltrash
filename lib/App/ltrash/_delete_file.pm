# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_delete_file;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use File::Basename;
use File::Copy qw (mv);
use App::ltrash::_get_path;
use App::ltrash::_url_encode;
use App::ltrash::_remove_file;
use App::ltrash::_file_deep_copy;

our @EXPORT = qw {
  _delete_file
};

use subs qw {
  _delete_file
};

# ============================================
# 移动一个文件到回收站
#
# 参数:
# \%trash_env
# $文件的绝对路径
# ============================================
sub _delete_file ($$) {
  my ($trash_env, $file_src) = (shift, shift);
  my $info_format = <<'INFO_FORMAT';
[Trash Info]
Path=%s
DeletionDate=%s
INFO_FORMAT

  unless (-e $file_src or -l $file_src) {
    say STDERR "WW: 文件\"$file_src\" 不存在，跳过。";
    return 0;
  }

  # 后缀从2 开始，不断尝试，直到一个不存在的文件名+ 后缀组合
  my $suffix = 2;
  my $file_dest = _get_trash_absolute_path
                    ($trash_env, 'file', basename $file_src);
  my $file_to_try = $file_dest;
  while (-e $file_to_try or -l $file_to_try) {
    $file_to_try = "$file_dest.$suffix";
    ++$suffix;
  }

  # 得到目标文件名
  $file_dest = $file_to_try;

  # 得到.trashinfo 文件名
  my $info_dest = join '.',
                    (_get_trash_absolute_path
                      $trash_env, 'info', basename $file_dest),
                    ('trashinfo');

  # 得到.trashinfo 文件要求的时间格式
  # reverse 之后分别为：年，月，日，时，分，秒
  my @info_date = reverse ((localtime)[0..5]);

  # 调整日期格式
  $info_date[0] += 1900;                          # 年份+ 1900
  ++$info_date[1];                                # 月份+ 1
  $info_date[$_] = sprintf "%02d", $info_date[$_] # 除了年份，其余字段不够两位补0
    for (1..@info_date-1);
  $info_date[0] = sprintf "%04d", $info_date[0];  # 年份不够4 位补0（防变态）

  # 构造完整时间格式：
  # 日期各部分之间用'-' 相连，时间各部分之间用':' 相连，日期和时间之间用'T' 相连
  my $info_date = join 'T',
                    (join '-', @info_date[0..2]),
                    (join ':', @info_date[3..5]);

  # 检查源目录权限
  say STDERR "\nWW: 无法删除文件，检查目录\"", dirname ($file_src), " \"权限。"
    and return 0
    unless -w dirname $file_src;

  # 移动文件到回收站
  eval {
    if ((stat $file_src)[0] ne $trash_env->{DEV_ID}) {
      _file_deep_copy 0, $file_src, $file_dest;
      _remove_file_recursively $file_src;
    } else {
      mv $file_src, $file_dest;
    }
  };
  if ($@) {
    say STDERR
      "EE: 删除文件\"$file_src\" 时出错，跳过，相应info 文件未生成。\n",
        "\t错误信息: $@";
    return 0;
  }

  # 生成.trashinfo 文件
  eval {
    open my $file_fh, '>', $info_dest;

    # 写入.trashinfo 文件信息
    printf $file_fh $info_format,
                      _url_encode ($file_src),
                      $info_date;
    close $file_fh;
  };
  if ($@) {
    say STDERR "EE: 生成文件\"$info_dest\" 时出错，跳过，该文件未生成。\n",
        "\t错误信息: $@";

    # 删除掉可能生成的垃圾文件
    _remove_file_recursively $info_dest
      if -e $info_dest or -l $info_dest;

    return 0;
  }

  return 1;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_delete_file

=head1 描述

请忘掉这个模块，避免使用它！

=cut

