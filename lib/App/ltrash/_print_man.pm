# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_print_man;

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
require Pod::Usage;

our @EXPORT = qw {
  _print_man
};

use subs qw {
  _print_man
};

# ============================================
# 打印手册
# 函数使用最终调用脚本的POD 文档
# 所以请将POD 文档置于该脚本
# 这些POD 文档会被当作手册打印
# 有些发行版的groff 无法处理Unicode 字符
# 这种情况下该函数会输出乱码
# ============================================
sub _print_man {

  my $orig_programe_name = $0;

  Pod::Usage::pod2usage (
    -input    =>  $orig_programe_name,
    -verbose  =>  2,
    -exitval  =>  0,
  );

  return 1;
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_print_man

=head1 描述

将$0 中的POD 文档打印为手册。

=head1 用法

  use App::ltrash::_print_man;

  _print_man;

  =encoding utf8

  =head1 It Works!

  =head1 运行良好！

  =cut

=cut

