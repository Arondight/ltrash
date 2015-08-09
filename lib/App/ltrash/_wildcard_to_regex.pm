# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_wildcard_to_regex;

our $VERSION = '0.10';

use strict;
use warnings;
use 5.010;
use Exporter qw (import);

our @EXPORT = qw {
  _wildcard_to_regex
};

use subs qw {
  _wildcard_to_regex
};

# ============================================
# 将通配符转换为等价的正则表达式
#
# 参数:
# @通配符匹配串列表
# ============================================
sub _wildcard_to_regex (@) {
  # 转换整个参数列表
  for my $index (0..@_-1) {
    $_[$index] =~ s{\.}{\\\.}og;           # 所有的'.' 换为'\.'
    $_[$index] =~ s{(?<!\\)\*}{\.*}og;     # 前面无'\' 的'*' 换为'.*'
    $_[$index] =~ s{(?<!\\)\?}{\.}og;      # 前面无'\' 的'?' 换为'.'
    $_[$index] =~ s{^(.*)$}{\^$1\$}og;     # 首尾标记
  }

  return @_;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_wildcard_to_regex

=head1 描述

将通配符转换为等价的PCRE 正则表达式。

会自动添加正则首位标记，所以你如果想在一段文字中查找C<world> 或者C<word>，
对应的通配符应当是C<*wor?d*> 而不是C<wor?d>。

=head1 用法

  use App::ltrash::_wildcard_to_regex;

  my $wildcard = 'http://*.com/index.htm?';
  my $regex = _wildcard_to_regex $wildcard;

=cut

