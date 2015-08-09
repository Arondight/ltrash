# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_file_filter;

our $VERSION = '0.11';

use strict;
use warnings;
use 5.010;
use File::Basename;
use Time::Local;
use App::ltrash::_file_type;
use App::ltrash::_get_path;
use App::ltrash::_wildcard_to_regex;
use App::ltrash::_backup_invalid_file;
use Exporter qw (import);

our @EXPORT = qw {
  _trash_file_regex_filter
  _trash_file_size_filter
  _trash_file_time_filter
  _trash_file_type_filter
};

use subs qw {
  _trash_file_regex_filter
  _trash_file_size_filter
  _trash_file_time_filter
  _trash_file_type_filter
};

# ============================================
# 参数接受回收站中的文件列表
# 对其进行时间过滤并返回过滤结果
#
# 参数:
# \%infos
# $开始时间串
# $结束时间串
# @文件绝对路径列表
# ============================================
sub _trash_file_time_filter ($$$@) {
  my $infos = shift;
  my ($begin_time, $end_time) = (shift, shift);
  my @file_list = @_;
  my %file_list = ();

  # 首先将时间转换为能够被timelocal 正确识别的列表
  my @begin_time = reverse split /-/, $begin_time;
  my @end_time = reverse split /-/, $end_time;
  # 年份换算成相对于1900 的偏移量
  $begin_time[5] -= 1900;
  $end_time[5] -= 1900;
  # 月份换算成(0..11) 的格式
  --$begin_time[4];
  --$end_time[4];

  # 换算成秒数
  $begin_time = timelocal @begin_time;
  $end_time = timelocal @end_time;

  # 对每个文件进行时间过滤
  for my $file (@file_list) {
    unless (exists $infos->{+basename $file}) {
      say STDERR
        "EE: 文件$file 没有找到对应.trashinfo 文件，已经移动到备份目录。";
      _backup_invalid_file $file;
    }

    # 获得文件的时间字段列表，各个字段用'-'、'T' 和':' 分割的
    my @file_time = reverse split /[\-T:]/, @{ $infos->{+basename $file} }[1];
    $file_time[5] -= 1900;  # 年份换算成相对于1900 的偏移量
    --$file_time[4];        # 月份换算成(0..11) 的形式
    my $file_time = timelocal @file_time;

    # 判断时间是否在指定范围内
    $file_list{$file} = 1
      if ($begin_time < $file_time and $file_time < $end_time);
  }

  return keys %file_list;
}

# ============================================
# 参数接受回收站中的文件列表
# 对其进行正则过滤并返回过滤结果
#
# 参数:
# \%infos
# \%trash_env
# $正则标记
# @待匹配串列表
# ============================================
sub _trash_file_regex_filter ($$$@) {
  my ($infos, $trash_env) = (shift, shift);
  my $bool_pcre = shift;
  my @keyword_list = @_;
  my %file_list = ();   # 只使用keys，使用散列因为具有key 不重复的性
  my @all_files = ();

  # %infos 中的key 即为回收站files 目录的文件列表
  for my $file (keys %$infos) {
    push @all_files, _get_trash_absolute_path ($trash_env, 'file', $file)
  }

  # 把通配符换成等价的pcre 正则
  @keyword_list = _wildcard_to_regex @keyword_list
    if 0 == $bool_pcre;

  # 获得所有匹配串参数匹配的文件列表
  for my $keyword (@keyword_list) {
    # 获得所有匹配的文件
    my @matching_list =
      map {
        my $filename = basename $_;

        # 删除源文件名后可能多余的数字后缀
        $filename =~ s/^(.+)(?:\.\d+)/$1/o
          if $filename ne basename @{ $infos->{$filename} }[0];

        # 返回匹配结果
        $filename =~ /$keyword/ ? $_ : ();
      } @all_files;

    # 然后转化为键值
    $file_list{$_} = 1
      for @matching_list;
  }

  # 这是所有匹配的不重复文件列表
  return keys %file_list;
}

# ============================================
# 参数接受文件列表
# 对其进行类型过滤并返回过滤结果
#
# 参数:
# $文件类型
# @待匹配串列表
# ============================================
sub _trash_file_type_filter ($@) {
  my $type = _get_type shift;
  my @all_files = @_;
  my %file_list = ();

  my $type_regex = $type;
  for my $file (@all_files) {
    if (_get_type '普通' eq $type) {
      $type_regex = join ')|(',
                          $type,
                          _get_type '文本',
                          _get_type '脚本',
                          _get_type '图片',
                          _get_type '音频',
                          _get_type '视频',
                          _get_type '程序',
                          _get_type '归档';
    }

    $type_regex = join '', '^(', $type_regex, ')$';

    $file_list{$file} = 1
      if _file_type ($file) =~ /$type_regex/;
  }

  return keys %file_list;
}

# ============================================
# 参数接受文件列表
# 对其进行字节过滤并返回结果
#
# 参数：
# $最小字节数
# $最大字节数
# @文件列表
# ============================================
sub _trash_file_size_filter ($$@) {
  my ($min_size, $max_size) = (shift, shift);
  my @all_files = @_;
  my %file_list;

  for my $filename (@all_files) {
    my $size = -l $filename ? (lstat $filename)[7] : (stat $filename)[7];

    if (defined $min_size) {
      next
        if $min_size > $size;
    }

    if (defined $max_size) {
      next
        if $max_size < $size;
    }

    $file_list{$filename} = 1;
  }

  return keys %file_list;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_file_filter

=head1 描述

请忘掉这个模块，避免使用它！

=cut

