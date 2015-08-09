# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_get_readable_time;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use Time::Piece;
use Time::Seconds;
use Time::Local;

our @EXPORT = qw {
  _get_readable_time
  _get_readable_time_error
};

use subs qw {
  _get_readable_time_error
};

# ============================================
# 初始化时间参数转换为程序可以处理的格式
#
# 参数:
# $开始时间串
# $结束时间串
# ============================================
sub _get_readable_time ($$) {
  my @time = (shift, shift);
  # 存放合法的开始和结束时间
  my @legal_time = ();
  # 时间的分隔符模式
  my $pattern = qr{-|:|\.|/|_};

  # 如果为'any'，设置时间为最大值或者最小值
  if ($time[0] =~ /any/i) {
    $legal_time[0] = '0000-01-01-00-00-00';
  }
  if ($time[1] =~ /any/i) {
    $legal_time[1] = '9999-12-31-23-59-59';
  }
  # 如果是'now'，设置为当前时间或者抛出非法
  if ($time[0] =~ /now/i) {
    _get_readable_time_error (
      'now', '"now" 只能用于--end-time, -e 参数之后');
  }
  if ($time[1] =~ /now/i) {
    my @now = reverse ((localtime)[0..5]);
    $now[0] += 1900;  # 年份+ 1900
    ++$now[1];        # 月份+ 1
    $legal_time[1] = sprintf "%04s".("-%02s"x5), @now;
  }

  # 已经处理过的待处理字段设置为undef
  for my $index (0..@legal_time-1) {
    $time[$index] = undef
      if $legal_time[$index];
  }

  # 处理剩下的字段
  for my $index (0..@time-1) {
    # 处理过的内容则跳过
    next
      unless defined $time[$index];

    # 如果是相对时间的格式，计算出时间串
    if ($time[$index] =~ m{^((\d\.?)+)([ymdhMs])}o) {
      my ($offset, $suffix) = ($1, $3);
      my $time_wanted = Time::Seconds->new (time);
      SWITCH: {
        # 偏移是年份
        'y' eq $suffix and do {
          $time_wanted -= $offset * ONE_YEAR; last SWITCH;
        };
        # 偏移是月份
        'm' eq $suffix and do {
          $time_wanted -= $offset * ONE_MONTH; last SWITCH;
        };
        # 偏移是日份
        'd' eq $suffix and do {
          $time_wanted -= $offset * ONE_DAY; last SWITCH;
        };
        # 偏移是小时
        'h' eq $suffix and do {
          $time_wanted -= $offset * ONE_HOUR; last SWITCH;
        };
        # 偏移是分钟
        'M' eq $suffix and do {
          $time_wanted -= $offset * ONE_MINUTE; last SWITCH;
        };
        # 偏移是秒数
        's' eq $suffix and do {
          $time_wanted -= $offset * 1; last SWITCH;
        };
        DEFAULT: {
          _get_readable_time_error (
            $time[$index], '后缀不符合要求，使用-h 参数查看帮助');
        }
      }

      # 现在我们得到偏移时间了，转换localtime 之前进行一次取整
      my @time_wanted = reverse ((localtime (int $time_wanted->seconds))[0..5]);
      $time_wanted[0] += 1900;  # 年份+ 1900
      ++$time_wanted[1];        # 月份+ 1

      # 把偏移格式替换为计算得到的绝对时间
      $time[$index] = join '-', @time_wanted;
    }

    _get_readable_time_error ($time[$index], '格式无法识别')
      unless $time[$index] =~ /\d+($pattern)?/o;  # $pattern 是不变的、已编译过的正则

    # 按照规则将时间的各部分分离
    my @this_time = split m{$pattern}o, $time[$index];  # $pattern ……

    # 检查6 个字段（年月日时分秒）的指定合法性
    # 单独提醒年份为了给出'-mm' 此类日期格式的变态
    _get_readable_time_error ($time[$index], '年份未指定')
      unless defined $this_time[0] and '' ne $this_time[0];
    # 之后依次检查其后的字段，防止给出'yy--mm' 此类日期格式的变态
    for my $index2 (1..5) {
      _get_readable_time_error (
        $time[$index], '未指定的字段不能在指定的字段之前')
        if ! defined $this_time[$index2-1] and defined $this_time[$index2];
    }
    # 检查各字段是否为纯数字
    for (@this_time) {
      _get_readable_time_error ($_, '格式无法识别')
        unless (/^\d+$/o);
    }

    # 首先移除用户可能多输入的字段，取前6 个
    pop @this_time
      for 5+1..@this_time-1;

    # 现在把未指定字段填充0，其后会进行格式补齐
    # 月份和日份从1 开始，年份和时分秒从0 开始
    push @this_time, ((1 == $_ or 2 == $_) ? 1 : 0)
      for @this_time-1+1..5;

    # 检查各字段取值范围概念上的合法性
    _get_readable_time_error (
      $time[$index], '年份的取值应该在1970-9999 之间')
      if $this_time[0] < 1970 or $this_time[0] > 9999;
    _get_readable_time_error (
      $time[$index], '月份的取值应该在1-12 之间')
      if $this_time[1] < 1 or $this_time[1] > 12;
    _get_readable_time_error (
      $time[$index], '日份的取值应该在1-31 之间')
      if $this_time[2] < 1 or $this_time[2] > 31;
    _get_readable_time_error (
      $time[$index], '小时的取值应该在0-23 之间')
      if $this_time[3] < 0 or $this_time[3] > 23;
    _get_readable_time_error (
      $time[$index], '分钟的取值应该在0-59 之间')
      if $this_time[4] < 0 or $this_time[4] > 59;
    _get_readable_time_error (
      $time[$index], '秒数的取值应该在0-59 之间')
      if $this_time[5] < 0 or $this_time[5] > 59;

    # 检查各字段取值范围逻辑上的合法性
    my @has_30_days = (4, 6, 9, 11);    # 四六九冬三十天
    for my $month_30_days (@has_30_days) {
      _get_readable_time_error (
        $time[$index], "$this_time[1] 月没有第31 天")
        if ($this_time[1] == $month_30_days and 31 == $this_time[2]);
    }
    # 二月单独处理，分闰年和非闰年
    my $february_days = 28;             # 唯有二月二十八
    ++$february_days                    # 闰年二月二十九
      if 0 == $this_time[0] % 400
        or 0 == $this_time[0] % 4 && $this_time[0] % 100;
    _get_readable_time_error (
      $time[$index], "$this_time[0] 年2 月最多有$february_days 天")
      if $this_time[2] > $february_days and 2 == $this_time[1];

    # 现在各个字段都被认为是合法的
    # 可以进行格式化处理了
    $this_time[0] = sprintf "%04d", $this_time[0];    # 年份字段4 位
    $this_time[$_] = sprintf "%02d", $this_time[$_]   # 其他字段2 位
      for (1..5);

    # 现在字段被认为是合法而且格式化的
    $legal_time[$index] = join '-', @this_time;
  }

  return @legal_time;
}

# ============================================
# 给出初始化时间格式串的错误并退出
#
# 参数:
# $错误的日期格式串
# $出错信息
# ============================================
sub _get_readable_time_error ($$) {
  my ($date_format, $error_msg) = (shift, shift);
  my $error_format = <<'INIT_TIME_PARA_ERROR';
EE: 在日期字段"%s" 中，%s。
INIT_TIME_PARA_ERROR
  printf STDERR $error_format, $date_format, $error_msg;

  exit 1;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_get_readable_time

=head1 描述

请忘掉这个模块，避免使用它！

=cut

