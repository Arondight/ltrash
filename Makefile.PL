#!/usr/bin/env perl
# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #

package main;

use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %parms = (
  NAME          => 'ltrash',
  AUTHOR        => '秦凡东 <shell_way@foxmail.com>',
  ABSTRACT      => '一个控制台回收站程序',
  VERSION_FROM  => 'lib/App/ltrash.pm',

  PM  => {
    'lib/App/ltrash.pm'                                   =>
      '$(INST_LIBDIR)/App/ltrash.pm',
    'lib/App/ltrash/_get_matching_file.pm'                =>
      '$(INST_LIBDIR)/App/ltrash/_get_matching_file.pm',
    'lib/App/ltrash/_get_path.pm'                         =>
      '$(INST_LIBDIR)/App/ltrash/_get_path.pm',
    'lib/App/ltrash/_get_readable_time.pm'                =>
      '$(INST_LIBDIR)/App/ltrash/_get_readable_time.pm',
    'lib/App/ltrash/_file_type.pm'                        =>
      '$(INST_LIBDIR)/App/ltrash/_file_type.pm',
    'lib/App/ltrash/_wildcard_to_regex.pm'                =>
      '$(INST_LIBDIR)/App/ltrash/_wildcard_to_regex.pm',
    'lib/App/ltrash/_get_size.pm'                         =>
      '$(INST_LIBDIR)/App/ltrash/_get_size.pm',
    'lib/App/ltrash/_file_deep_copy.pm'                   =>
      '$(INST_LIBDIR)/App/ltrash/_file_deep_copy.pm',
    'lib/App/ltrash/_delete_file.pm'                      =>
      '$(INST_LIBDIR)/App/ltrash/_delete_file.pm',
    'lib/App/ltrash/_backup_invalid_file.pm'              =>
      '$(INST_LIBDIR)/App/ltrash/_backup_invalid_file.pm',
    'lib/App/ltrash/_url_encode.pm'                       =>
      '$(INST_LIBDIR)/App/ltrash/_url_encode.pm',
    'lib/App/ltrash/_print_man.pm'                        =>
      '$(INST_LIBDIR)/App/ltrash/_print_man.pm',
    'lib/App/ltrash/_file_filter.pm'                      =>
      '$(INST_LIBDIR)/App/ltrash/_file_filter.pm',
    'lib/App/ltrash/_remove_file.pm'                      =>
      '$(INST_LIBDIR)/App/ltrash/_remove_file.pm',
  },

  EXE_FILES => ['bin/ltrash'],

  PREREQ_PM => {
    'Cwd'             => '3.47',
    'FileHandle'      => '2.02',
    'File::Basename'  => '2.85',
    'File::Spec'      => '3.47',
    'File::Copy'      => '2.29',
    'File::Path'      => '2.09',
    'File::Glob'      => '1.23',
    'Getopt::Long'    => '2.42',
    'Time::Piece'     => '1.27',
    'Time::Seconds'   => '1.27',
    'Time::Local'     => '1.2300',
    'Pod::Usage'      => '1.63',
  },

  # 取消注释则允许生成手册文件
  # 程序手册
  #MAN1PODS            => {},
  # 模块手册
  #MAN3PODS            => {},

  dist                => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean               => {FILES => ''},
);

if ($ExtUtils::MakeMaker::VERSION ge '6.46') {
  $parms{META_MERGE} = {
    resources => {
      homepage    => 'https://github.com/Arondight/ltrash',
      bugtracker  => 'https://github.com/Arondight/ltrash/issues',
      license     => 'https://www.gnu.org/licenses/gpl.html',
      repository  => 'git://github.com/Arondight/ltrash.git',
    }
  };
}

if ($ExtUtils::MakeMaker::VERSION ge '6.48') {
    $parms{MIN_PERL_VERSION} = 5.008008;
}

WriteMakefile %parms;

1;

