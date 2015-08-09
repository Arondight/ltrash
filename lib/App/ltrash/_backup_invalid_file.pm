# ==========================================  #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_backup_invalid_file;

use strict;
use warnings;
use 5.010;
use Exporter qw (import);
use File::Basename;
use File::Spec;
use File::Copy qw (mv);
use App::ltrash::_remove_file;
use App::ltrash::_file_deep_copy;

our $VERSION='0.10';

our @EXPORT = qw {
  _backup_invalid_file
};

use subs qw {
  _backup_invalid_file
};

# ============================================
# 将文件移动到备份目录中
#
# 参数:
# $无效文件目录
# @trash_env{TRASH_FILE} 目录的文件名
# ============================================
sub _backup_invalid_file ($@) {
  my $dir = shift;
  for my $file (@_) {
    say STDERR "EE: 文件\"$file\" 不存在"
      unless -e $file or -l $file;

    # 得到合法后缀
    my $file_dest = File::Spec->catfile ($dir, basename $file);
    my $suffix = 2;
    my $file_to_try = $file_dest;
    while (-e $file_to_try or -l $file_to_try) {
      $file_to_try = $file_dest.$suffix;
      ++$suffix;
    }

    eval {
      if ((stat $file)[0] ne (stat $dir)[0]) {
        _file_deep_copy 0, $file, $file_to_try;
        _remove_file_recursively $file;
      } else {
        mv $file, $file_to_try;
      }
    };
    if ($@) {
      say STDERR "EE: 移动文件出错: $@";
      return 0;
    }
  }
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_backup_invalid_file

=head1 描述

请忘掉这个模块，避免使用它！

=cut

