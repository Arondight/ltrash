# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash;

our $VERSION = '0.94';

use strict;
use warnings;
use 5.010;
use Env;
use FileHandle;
use File::Basename;
use File::Spec;
use File::Glob qw (:glob);
use File::Path qw (mkpath rmtree);
use File::Copy qw (mv);
use Getopt::Long qw (GetOptions);
use App::ltrash::_delete_file;
use App::ltrash::_remove_file;
use App::ltrash::_file_type;
use App::ltrash::_file_filter;
use App::ltrash::_get_size;
use App::ltrash::_get_path;
use App::ltrash::_file_deep_copy;
use App::ltrash::_url_encode;
use App::ltrash::_wildcard_to_regex;
use App::ltrash::_get_readable_time;
use App::ltrash::_get_matching_file;
use App::ltrash::_backup_invalid_file;
use App::ltrash::_print_man;

use subs qw {
  _is_switch
  _get_switch
  _set_env
  _read_info
  _hashing_para
  _delete
  _erase
  _clean
  _list_all
  _search
  _recover
  _which_invalid_dir
  _clean_invalid_file
  _print_version
  _print_help
};

# 数组散列，用于储存已删除的文件信息
# key = 源文件名
# value = (源路径, 删除日期)
my %infos = (
  "file"    =>  ["/path/to/file"   =>  "2345-06-07T08:09:10"],
  "file.2"  =>  ["/path2/to/file"  =>  "3456-07-08T09:10:11"],
);
# 环境变量，注意其中的'undef' 是一个字符串
my %trash_env = qw {
  TRASH_INFO_PATH   undef
  TRASH_INFO_PATH   undef
  TRASH_FILE_PATH   undef
  DEV_ID            undef
};

# ============================================
# 处理参数，生成参数开关散列
#
# 参数:
# @命令行参数列表
# ============================================
sub new (@) {
  my $type = shift;
  my $class = ref $type || $type;

  my $self = _hashing_para @_;
  bless $self, $class;

  return $self;
}

sub DESTORY {
  my $self = shift;

  $self->SUPER::DESTORY
    if $self->can ("SUPER::DESTORY");

  delete @infos{+keys %infos};
  delete @trash_env{+keys %trash_env};
  # _hashing_para 中未释放的数组散列
  delete @{$self}{ +keys %{$self} };
}

# ============================================
# 返回一个已经存在的开关
# 如果参数不是合法开关返回0
# 合法则返回该开关(1)
#
# 参数:
# $开关名
# ============================================
sub _is_switch ($) {
  my $name = shift;

  # 合法开关散列
  my %switch = qw {
        delete              唯
        Erase               愿
        Clean               你
        list-all            与
        search              围
        recover             绕
        pcre                你
        force               的
        link-follow         这
        count-number        个
        begin-time          世
        end-time            界
        type                未
        min-size            来
        max-size            也
        version             能
        help                一
        man                 直
        which-invalid-dir   幸
        clean-invalid-file  福
  };

  die "DIE: 期望一个参数但是没有得到。"
    unless defined $name;

  return $name
    if exists $switch{$name};

  return 0;
}

# ============================================
# 检查开关是否存在
# 存在则返回该开关(1)
#
# 参数:
# $开关名
# ============================================
sub _get_switch ($) {
  my $switch_name = shift;

  die "DIE: 期望一个参数但是没有得到。"
    unless defined $switch_name;

  # _is_switch 会返回合法开关的名字或者0
  my $switch = _is_switch $switch_name;

  return $switch
    if $switch;

  die "DIE: [--$switch_name] 不是一个开关。";
}

# ============================================
# 设置环境变量散列%trash_env
# 分析构造方法bless 到类名的%$self 数组散列
# 并且调用方法作出响应
# ============================================
sub run {
  my $self = shift;

  # 下面需要设置每个可能为空的开关值
  my $bool_force = @{ $self->{+_get_switch 'force'} } ? 1 : 0;
  my $bool_follow = @{ $self->{+_get_switch 'link-follow'} } ? 1 : 0;
  my $bool_pcre = @{ $self->{+_get_switch 'pcre'} } ? 1 : 0;
  my $bool_number = @{ $self->{+_get_switch 'count-number'} } ? 1 : 0;

  # 两个时间参数和类型参数未设置则设置为'any'
  # 为整个列表赋值，并非手误
  @{ $self->{+_get_switch 'begin-time'} } = 'any'
    unless @{ $self->{+_get_switch 'begin-time'} };
  @{ $self->{+_get_switch 'end-time'} } = 'any'
    unless @{ $self->{+_get_switch 'end-time'} };
  @{ $self->{+_get_switch 'type'} } = 'any'
    unless @{ $self->{+_get_switch 'type'} };

  # 设置文件大小上下限
  # 为整个列表赋值，并非手误
  @{ $self->{+_get_switch 'min-size'} } =
    _size_by_byte @{ $self->{+_get_switch 'min-size'} }[0];
  @{ $self->{+_get_switch 'max-size'} } =
    _size_by_byte @{ $self->{+_get_switch 'max-size'} }[0];

  # 首先填充一次%infos
  _set_env
    or return 0;
  _read_info
    or return 0;

  SWITCH: {
    # 打印版本信息
    @{ $self->{+_get_switch 'version'} } and do {
      _print_version
        or return 0;
      last SWITCH;
    };

    # 打印帮助
    @{ $self->{+_get_switch 'help'} } and do {
      _print_help
        or return 0;
      last SWITCH;
    };

    # 打印手册
    @{ $self->{+_get_switch 'man'} } and do {
      _print_man
        or return 0;
      last SWITCH;
    };

    # 移动文件到回收站，支持-t/-n/-N/-c/-l/-p  参数
    @{ $self->{+_get_switch 'delete'} } and do {
      _delete               @{ $self->{+_get_switch 'type'} }[0],
                            @{ $self->{+_get_switch 'min-size'} }[0],
                            @{ $self->{+_get_switch 'max-size'} }[0],
                            $bool_number, $bool_follow, $bool_pcre,
                            @{ $self->{+_get_switch 'delete'} }
        or return 0;
      last SWITCH;
    };

    # 删除回收站中的文件，支持-b/-e/-t/-n/-N/-c/-p 参数
    @{ $self->{+_get_switch 'Erase'} } and do {
      _erase                @{ $self->{+_get_switch 'begin-time'} }[0],
                            @{ $self->{+_get_switch 'end-time'} }[0],
                            @{ $self->{+_get_switch 'type'} }[0],
                            @{ $self->{+_get_switch 'min-size'} }[0],
                            @{ $self->{+_get_switch 'max-size'} }[0],
                            $bool_number, $bool_pcre,
                            @{ $self->{+_get_switch 'Erase'} }
        or return 0;
      last SWITCH;
    };

    # 清空回收站，支持-f 参数
    @{ $self->{+_get_switch 'Clean'} } and do {
      _clean                $bool_force
        or return 0;
      last SWITCH;
    };

    # 打印回收站的所有文件，支持-b/-e/-t/-n/-N/-c 参数
    @{ $self->{+_get_switch 'list-all'} } and do {
      _list_all             @{ $self->{+_get_switch 'begin-time'} }[0],
                            @{ $self->{+_get_switch 'end-time'} }[0],
                            @{ $self->{+_get_switch 'type'} }[0],
                            @{ $self->{+_get_switch 'min-size'} }[0],
                            @{ $self->{+_get_switch 'max-size'} }[0],
                            $bool_number
        or return 0;
      last SWITCH;
    };

    # 查找回收站中的文件，支持-b/-e/-t/-n/-N/-c/-p 参数
    @{ $self->{+_get_switch 'search'} } and do {
      _search               @{ $self->{+_get_switch 'begin-time'} }[0],
                            @{ $self->{+_get_switch 'end-time'} }[0],
                            @{ $self->{+_get_switch 'type'} }[0],
                            @{ $self->{+_get_switch 'min-size'} }[0],
                            @{ $self->{+_get_switch 'max-size'} }[0],
                            $bool_number, $bool_pcre,
                            @{ $self->{+_get_switch 'search'} }
        or return 0;
      last SWITCH;
    };

    # 恢复回收站中的文件，支持-b/-e/-t/-n/-N/-c/-f/-p参数
    @{ $self->{+_get_switch 'recover'} } and do {
      _recover              @{ $self->{+_get_switch 'begin-time'} }[0],
                            @{ $self->{+_get_switch 'end-time'} }[0],
                            @{ $self->{+_get_switch 'type'} }[0],
                            @{ $self->{+_get_switch 'min-size'} }[0],
                            @{ $self->{+_get_switch 'max-size'} }[0],
                            $bool_number, $bool_force, $bool_pcre,
                            @{ $self->{+_get_switch 'recover'} }
        or return 0;
      last SWITCH;
    };

    # 打印无效文件目录
    @{ $self->{+_get_switch 'which-invalid-dir'} } and do {
      _which_invalid_dir;
      last SWITCH;
    };

    # 删除所有无效文件，支持-f 参数
    @{ $self->{+_get_switch 'clean-invalid-file'} } and do {
      _clean_invalid_file   $bool_force;
      last SWITCH;
    };

    # 没有发现任何合法开关则弹出帮助信息
    DEFAULT: {
      say STDERR 'EE: 没有发现一个正确的动作选项。';
    }
  };

  return 1;
}

# ============================================
# 设置散列%trash_env
# ============================================
sub _set_env {
  %trash_env = ();

  die "DIE: 未发现环境变量HOME。"
    unless exists $ENV{HOME};

  # 设置环境变量
  my $xdg_data_home = File::Spec->catfile ($ENV{HOME}, '.local', 'share');
  $xdg_data_home = $ENV{XDG_DATA_HOME}
    if exists $ENV{XDG_DATA_HOME} and -d -w $ENV{XDG_DATA_HOME};
  $trash_env{TRASH_PATH} = File::Spec->catfile ($xdg_data_home, 'Trash');
  $trash_env{TRASH_INFO_PATH} = File::Spec->catfile (
                                  $trash_env{TRASH_PATH}, 'info');
  $trash_env{TRASH_FILE_PATH} = File::Spec->catfile (
                                  $trash_env{TRASH_PATH}, 'files');
  $trash_env{TRASH_BACKUP_PATH} = File::Spec->catfile (
                                  $trash_env{TRASH_PATH}, 'backup');

  say STDERR "EE：工作目录\"$xdg_data_home\" 存在但不可写。"
    and return 0
    unless -w $xdg_data_home;

  # 目录不存在则创建目录
  eval {
    mkpath $trash_env{TRASH_PATH}, 0, 0755
      unless -d -e $trash_env{TRASH_PATH};
    mkpath $trash_env{TRASH_INFO_PATH}, 0, 0755
      unless -d -e $trash_env{TRASH_INFO_PATH};
    mkpath $trash_env{TRASH_FILE_PATH}, 0, 0755
      unless -d -e $trash_env{TRASH_FILE_PATH};
    mkpath $trash_env{TRASH_BACKUP_PATH}, 0, 0755
      unless -d -e $trash_env{TRASH_BACKUP_PATH};
  };
  if ($@) {
    say STDERR "EE: 回收站目录创建失败，退出。";
    return 0;
  }

  # 设置回收站目录所在设备的设备号
  $trash_env{DEV_ID} = (stat $trash_env{TRASH_FILE_PATH})[0];

  # 检查各目录是否可写，因为权限可能在创建后变更
  my @work_dirs = grep { $_ ne 'DEV_ID' } keys %trash_env;
  for my $work_dir (@work_dirs) {
    return 0
      unless -d -w $trash_env{$work_dir};
  }

  return 1;
}

# ============================================
# 读取info 目录下的文件信息到散列%infos
# ============================================
sub _read_info {
  %infos = ();

  # 获得所有文件
  opendir File_Dir, $trash_env{TRASH_FILE_PATH}
    or die "DIE: 无法打开目录$trash_env{TRASH_FILE_PATH}";

  # 根据文件找到对应.trashinfo 文件并读取内容
  for my $file (readdir File_Dir) {
    next
      if $file =~ /^\.{1,2}$/o;

    # 获取对应.trashinfo 文件绝对路径
    my $info_file = join '.',
                      _get_trash_absolute_path
                        (\%trash_env, 'info', basename $file),
                      "trashinfo";

    # 下面分别读取每个.trashinfo 文件的内容到%infos
    unless (open Info_File, '<', $info_file) {
      my $invalid_file = basename $info_file;
      $invalid_file =~ s/(,*)\.trashinfo$/$1/o;
      $invalid_file = _get_trash_absolute_path
                        (\%trash_env, 'file', $invalid_file);
      _backup_invalid_file
        ($trash_env{TRASH_BACKUP_PATH}, $invalid_file);
      printf STDERR
        "WW: 无法读取信息文件\"%s\"，对应文件已经移动到备份目录\"%s\"。\n",
        basename ($info_file), $trash_env{TRASH_BACKUP_PATH};
      next;
    }

    # 用于储存源路径和删除时间
    my ($path_info, $delete_info) = ();
    # 逐行读入
    for my $line (<Info_File>) {
      $path_info = _url_decode ($1)
        if $line =~ /^path=(.+)$/oi;
      $delete_info = $1
        if $line =~ /^deletiondate=(.+)$/oi;
    }

    close Info_File;

    # 源文件名
    my $filename = basename $file;

    # 最后把获得的源路径和删除时间压入数组散列对应键
    # 同一个key 可能push 多个($path_info, $delete_info)
    push @{ $infos{$filename} }, $path_info, $delete_info;
  }

  closedir File_Dir;

  return 1;
}

# ===========================================
# 将参数列表转换为参数散列
#
# 参数:
# 命令行参数
# ============================================
sub _hashing_para (@) {
  state %para;

  @ARGV = @_;

  say '使用ltrash -h 查看帮助。'
    and exit
    unless @ARGV;

  Getopt::Long::Configure 'no_ignore_case', 'no_auto_help';

  # 填充%para 数组散列
  Getopt::Long::GetOptions (
    (sprintf 'd|%s=s{,}', _get_switch 'delete')          =>
      \@{ $para{+_get_switch 'delete'} },
    (sprintf 'E|%s=s{,}', _get_switch 'Erase')           =>
      \@{ $para{+_get_switch 'Erase'} },
    (sprintf 'C|%s!', _get_switch 'Clean')               =>
      \@{ $para{+_get_switch 'Clean'} },
    (sprintf 'a|%s!', _get_switch 'list-all')            =>
      \@{ $para{+_get_switch 'list-all'} },
    (sprintf 's|%s=s{,}', _get_switch 'search')          =>
      \@{ $para{+_get_switch 'search'} },
    (sprintf 'r|%s=s{,}', _get_switch 'recover')         =>
      \@{ $para{+_get_switch 'recover'} },
    (sprintf 'p|%s!', _get_switch 'pcre')                =>
      \@{ $para{+_get_switch 'pcre'} },
    (sprintf 'f|%s!', _get_switch 'force')               =>
      \@{ $para{+_get_switch 'force'} },
    (sprintf 'l|%s!', _get_switch 'link-follow')         =>
      \@{ $para{+_get_switch 'link-follow'} },
    (sprintf 'c|%s!', _get_switch 'count-number')        =>
      \@{ $para{+_get_switch 'count-number'} },
    (sprintf 'b|%s=s', _get_switch 'begin-time')         =>
      \@{ $para{+_get_switch 'begin-time'} },
    (sprintf 'e|%s=s', _get_switch 'end-time')           =>
      \@{ $para{+_get_switch 'end-time'} },
    (sprintf 't|%s=s', _get_switch 'type')               =>
      \@{ $para{+_get_switch 'type'} },
    (sprintf 'n|%s=s', _get_switch 'min-size')           =>
      \@{ $para{+_get_switch 'min-size'} },
    (sprintf 'N|%s=s', _get_switch 'max-size')           =>
      \@{ $para{+_get_switch 'max-size'} },
    (sprintf 'v|%s!', _get_switch 'version')             =>
      \@{ $para{+_get_switch 'version'} },
    (sprintf 'h|%s!', _get_switch 'help')                =>
      \@{ $para{+_get_switch 'help'} },
    (sprintf 'm|%s!', _get_switch 'man')                 =>
      \@{ $para{+_get_switch 'man'} },
    (sprintf '%s!', _get_switch 'which-invalid-dir')     =>
      \@{ $para{+_get_switch 'which-invalid-dir'} },
    (sprintf '%s!', _get_switch 'clean-invalid-file')    =>
      \@{ $para{+_get_switch 'clean-invalid-file'} },
  );

  return \%para;
}

# ============================================
# 确定要删除的文件列表
# 依次调用_delete_file 完成删除
#
# 参数:
# $文件类型
# $最小字节
# $最大字节
# $数量标记
# $链接跟随标记
# $正则标记
# @待匹配文件名列表
# ============================================
sub _delete ($$$@) {
  my $type = _get_type shift;
  my ($min_size, $max_size) = (shift, shift);
  my ($bool_number, $bool_follow, $bool_pcre) = (shift, shift, shift);
  my @file_list = ();       # 每次匹配的文件列表

  # 对--delete,-d 开关的列表元素进行操作
  for my $filename (@_) {
    # 根据之前或许的信息执行删除操作
    # 首先获得文件的绝对路径
    my $file = _get_pwd_absolute_path $filename;

    # 拒绝处理是根目录、根目录的一级子目录或者包含回收站路径的文件
    say STDERR "EE: 拒绝处理\"$file\"，跳过。"
      and next
      if $file =~ /^\/([^\/]+)?$/o
          or $trash_env{TRASH_PATH} =~ /$file/
          or $file =~ /$trash_env{TRASH_PATH}/;

    # 如果存在--link-follow,-l 参数，用链接文件的内容替换链接文件本身
    # 不存在则不替换，其后代码将打印符号链接不存在的信息
    if ($bool_follow) {
      $file = readlink $file
        if -l $file;
    }

    # 获得该文件名所匹配的文件列表
    if ($bool_pcre) {
      # 获得被pcre 正则匹配的文件列表
      my @matching_list = _get_matching_file $file;

      # 不存在抛出警告，此时文件列表为空
      unless ($bool_number) {
        unless (@matching_list) {
          printf STDERR "WW: 关键字\"%s\" 在目录\"%s\" 下无匹配，跳过。\n",
                        (basename $file), (dirname $file);
        }
      }

      # 现在只是无脑push，之后会进行去重
      push @file_list, @matching_list;
    } else {
      # 下面只判断文件是否存在，不必考虑通配符的问题
      # 因为通配符是shell 进行解释的，传递给程序的一定是文件列表
      # 但是用户的输入无法确保存在性，所以需要判断
      if (-e $file or -l $file) {
        push @file_list, $file;
      } else {
        # 不存在抛出警告，此时文件列表为空
        say STDERR "WW: 文件\"$file\" 不存在，跳过。"
          unless $bool_number;
      }
    }
  }

  # 现在利用散列的特性进行一次性去重
  my %file_list = map { $_ => 1 } @file_list;
  @file_list = keys %file_list;

  # 类型过滤
  @file_list = _trash_file_type_filter ($type, @file_list)
    unless $type eq _get_type 'any';

  # 大小过滤
  @file_list = _trash_file_size_filter
                ($min_size, $max_size, @file_list);

  # 然后通过扫描决定删除到回收站后的文件名
  # 策略是重名增加后缀%d，每次尝试后缀加一
  my $file_number = 0;
  for my $file (@file_list) {
    print "删除\"$file\"..."
      unless $bool_number;

    unless (-r $file) {
      unless (chmod 644, $file) {
        unless ($bool_number) {
          say '跳过。';
          say "WW：文件\"$file\" 不可读且无法更改权限。";
        }
        next;
      }
    }

    say "\t跳过。"
      and next
      unless _delete_file (\%trash_env, $file);

    say "\t完成。"
      unless $bool_number;
    ++$file_number
      if $bool_number;
  }

  say $file_number
    if $bool_number;

  return 1;
}

# ============================================
# 删除回收站中的文件
# 当要删除的文件数量等同于所有文件时
# 调用_clean
#
# 参数:
# $开始时间
# $终止时间
# $文件类型
# $最小字节
# $最大字节
# $数量标记
# $正则标记
# @待匹配关键字列表
# ============================================
sub _erase ($$@) {
  my ($begin_time, $end_time) = (shift, shift);
  my $type = _get_type shift;
  my ($min_size, $max_size) = (shift, shift);
  my ($bool_number, $bool_pcre) = (shift, shift);
  my @keyword_list = @_;
  my @all_files = ();
  my @file_list = ();

  # %infos 中的key 即为回收站files 目录的文件列表
  for my $file (keys %infos) {
    push @all_files, _get_trash_absolute_path
                      (\%trash_env, 'file', $file)
      unless $file =~ /^\.{1,2}$/o;
  }

  # 得到处理过的时间格式
  ($begin_time, $end_time) = _get_readable_time $begin_time, $end_time;

  # 正则过滤
  @file_list = _trash_file_regex_filter
                (\%infos, \%trash_env, $bool_pcre, @keyword_list);

  # 时间过滤
  @file_list = _trash_file_time_filter
                (\%infos, $begin_time, $end_time, @file_list);

  # 类型过滤
  @file_list = _trash_file_type_filter ($type, @file_list)
    unless $type eq _get_type 'any';

  # 大小过滤
  @file_list = _trash_file_size_filter
                ($min_size, $max_size, @file_list);

  # 下面判断行为是否等同于清空回收站
  # 如果等同调用_clean
  if (@file_list == @all_files) {
    my $no_force = 0;

    # 模拟无--force,-f 参数的情景以便产生确认询问
    _clean $no_force;

    return 0;
  }

  # 对得到的文件列表中的文件进行删除
  my $file_number = 0;
  for my $file (@file_list) {
    eval {
      printf '永久删除"%s"...', basename $file
        unless $bool_number;

      # 首先是文件本身
      _remove_file_recursively $file;
      # 然后是对应的.trashinfo 文件
      _remove_file_recursively (
        join '.',
              (_get_trash_absolute_path
                (\%trash_env, 'info', basename $file)),
              ("trashinfo")
      );

      say "\t完成。"
        unless $bool_number;
    };
    if ($@) {
      unless ($bool_number) {
        say '失败。\n';
        say STDERR "EE: 删除发生错误，跳过\n",
                    "\t错误信息: $@";
      }
    } else {
      ++$file_number;
    }
  }

  if ($bool_number) {
    say $file_number;
  } else {
    say "未发现匹配项，什么也没有做。"
      if 0 == $file_number;
  }

  return 1;
}

# ============================================
# 清空回收站的所有项目
#
# 参数:
# $强制标记
# ============================================
sub _clean ($) {
  my $bool_force = shift;

  if (0 == $bool_force) {
    print '确定要清空整个回收站吗？(Y/n): ';
    my $answer = getc;
    say '确认询问失败，回收站未被清空。'
      and return 0
      unless 'Y' eq $answer;
  }

  # 删除回收站info 目录
  print "正在清空回收站配置信息...\t";
  _remove_sub_file_recursively $trash_env{TRASH_INFO_PATH};
  say "完成";

  # 删除回收站files 目录
  print "正在清空回收站文件内容...\t";
  _remove_sub_file_recursively $trash_env{TRASH_FILE_PATH};
  say "完成";

  return 1;
}

# ========================
# 打印回收站所有文件的列表
#
# 参数:
# $开始时间串
# $结束时间串
# $文件类型
# $最小字节数
# $最大字节数
# $数量标记
# ============================================
sub _list_all ($$$$) {
  my ($no_pcre, $match_everything) = (0, '*');

  _search shift, shift, _get_type (shift), shift,
            shift, shift, $no_pcre, $match_everything;

  return 1;
}

# ============================================
# 查找回收站中的文件
#
# 参数:
# $开始时间串
# $结束时间串
# $文件类型
# $最小字节数
# $最大字节数
# $数量标记
# $正则标记
# @待匹配文件名列表
# ============================================
sub _search ($$$$$$$@) {
  my ($begin_time, $end_time) = (shift, shift);
  my $type = _get_type shift;
  my ($min_size, $max_size) = (shift, shift);
  my ($bool_number, $bool_pcre) = (shift, shift);
  my @keyword_list = @_;
  my @file_list = ();

  # 得到处理过的时间格式
  ($begin_time, $end_time) = _get_readable_time $begin_time, $end_time;

  # 正则过滤
  @file_list = _trash_file_regex_filter
                (\%infos, \%trash_env, $bool_pcre, @keyword_list);

  # 时间过滤
  @file_list = _trash_file_time_filter
                (\%infos, $begin_time, $end_time, @file_list);

  # 类型过滤
  @file_list = _trash_file_type_filter ($type, @file_list)
    unless $type eq _get_type 'any';

  # 大小过滤
  @file_list = _trash_file_size_filter
                ($min_size, $max_size, @file_list);

  # 现在得到的文件就是期望的
  # 输出这些文件的信息
  unless ($bool_number) {
    for my $file (sort @file_list) {
      my $file_basename = basename $file;

      say basename @{ $infos{$file_basename} }[0];
      print " └-[ 类型:", _file_type $file;
      print '  日期:', join ' ',
                        (split /T/,
                          @{ $infos{$file_basename} }[1]);
      print '  大小:', _human_readable_size (
                        -l $file ? (lstat $file)[7] : (stat $file)[7]);
      say "  路径:", dirname (@{ $infos{$file_basename} }[0]), " ]";
    }
  } else {
    say scalar @file_list;
  }

  return 1;
}

# ============================================
# 恢复回收站中的文件
#
# 参数:
# $开始时间串
# $结束时间串
# $文件类型
# $最小字节
# $最大字节
# $数量标记
# $强制标记
# $正则标记
# @待匹配文件名列表
# ============================================
sub _recover ($$$$$$$@) {
  my ($begin_time, $end_time) = (shift, shift);
  my $type = _get_type shift;
  my ($min_size, $max_size) = (shift, shift);
  my ($bool_number, $bool_force, $bool_pcre) = (shift, shift, shift);
  my @keyword_list = @_;
  my @file_list = ();
  my %file_dest = ();   # 数组散列，键值为需要恢复到键值路径的文件列表

  # 得到处理过的时间格式
  ($begin_time, $end_time) = _get_readable_time $begin_time, $end_time;

  # 正则过滤
  @file_list = _trash_file_regex_filter
                (\%infos, \%trash_env, $bool_pcre, @keyword_list);

  # 时间过滤
  @file_list = _trash_file_time_filter
                (\%infos, $begin_time, $end_time, @file_list);

  # 类型过滤
  @file_list = _trash_file_type_filter ($type, @file_list)
    unless $type eq _get_type 'any';

  # 大小过滤
  @file_list = _trash_file_size_filter
                ($min_size, $max_size, @file_list);

  # 首先填充%file_dest 数组散列
  for my $file (@file_list) {
    push @{ $file_dest{ @{ $infos{+basename $file} }[0] } }, $file;
  }

  # 如果有恢复到同目录的同名文件则询问选择
  for my $key (keys %file_dest) {
    if (@{ $file_dest{$key} } > 1) {
      printf "多个同名文件\"%s\" 需要恢复到目录\"%s\" 下，请选择一个:\n",
              basename ($key), dirname $key;

      # 打印重复列表中每个文件的具体信息
      for my $index (0..@{ $file_dest{$key} }-1) {
        printf "  %3d", $index + 1;
        print '  类型:', _file_type @{ $file_dest{$key} }[$index];
        print '  日期:', join ' ',
                          (split /T/,
                            @{ $infos{
                              +basename @{ $file_dest{$key} }[$index] } }[1]);
        say '  大小:', _human_readable_size (
                        -l $key
                          ? (lstat @{ $file_dest{$key} }[$index])[7]
                          : (stat @{ $file_dest{$key} }[$index])[7]);
      }

      # 获得编号
      my $index = -1;
      while (1) {
        print '要恢复的文件编号（0 为放弃）: ';
        chomp (my $number = <STDIN>);

        next
          if $number =~ /[^\d]/o;

        # 下标是从0 开始的，而列表中我们从1 开始计数
        $index = $number - 1;

        next
          if $index > (@{ $file_dest{$key} } - 1);

        # 输入合法则跳出死循环
        last;
      }

      # 替换文件列表
      if (0 == $index + 1) {
        # 如果得到输入0，则删除对应键值
        #
        delete $file_dest{$key};
      } else {
        # 否则把整个列表用编号表示的文件替换掉
        #
        @{ $file_dest{$key} } = (@{ $file_dest{$key} }[$index]);
      }
    }
  }

  # 现在根据%file_dest 的value 数组内容逐个恢复文件
  my $file_number = 0;
  for my $file_dest (keys %file_dest) {
    my $file_src = @{ $file_dest{$file_dest} }[0];
    my $filename = basename $file_dest;
    my $dirname = dirname $file_dest;

    # 如果目标路径不存在，试图建立或者跳过
    unless (-d $dirname) {
      if (0 == $bool_force) {
        # 没有指定-f 参数则试图询问
        #
        my $create_dir = 0;
        print "路径\"$dirname\" 已不存在，试图创建吗？(y/n): ";
        $create_dir = <STDIN>;

        if ($create_dir =~ /y/i) {
          eval {
            mkpath $dirname, 0, 0755;
          };
          if ($@) {
            say "WW: 无法创建目标目录\"$dirname\"，跳过。";
            next;
          }
        } else {
          say "WW: 停止处理\"$filename\"，跳过。";
          next;
        }
      } else {
        eval {
          mkpath $dirname, 0, 0755;
        };
        if ($@) {
          say "WW: 无法创建目标目录\"$dirname\"，跳过。";
          next;
        }
      }
    }

    if (0 == $bool_force) {
      # 没有指定-f 参数则寻找可以规避冲突的文件名
      #
      my $suffix = 2;
      my $file_to_try = $file_dest;
      while (-e $file_to_try or -l $file_to_try) {
        $file_to_try = "$file_dest.$suffix";
        ++$suffix;
      }

      # 现在得到的就是规避了冲突的文件名
      $file_dest = $file_to_try;
    }

    # 为1 则跳过该文件的处理
    my $skip = 0;

    printf "恢复文件\"%s\" => \"%s\" ...\t", $filename, $file_dest
      unless $bool_number;

    unless (-W dirname $file_dest) {
      unless ($bool_number) {
        say '失败。';
        say "WW: 目标目录\"", dirname ($file_dest), "\" 不可写，跳过。";
      }
      $skip = 1;
      $@ = undef;
      return;
    }

    # 没有读权限首先改变权限，因为需要读取文件内容
    unless (-r $file_src) {
      unless (chmod 644, $file_src) {
        unless ($bool_number) {
          say '失败。';
          say "WW：文件\"$file_src\" 不可读且无法更改权限。",
              '你可以使用-E 参数永久删除这个文件。';
        }
        $skip = 1;
        $@ = undef;
        return;
      }
    }

    eval {
      # 恢复文件
      if ((stat dirname $file_dest)[0] ne $trash_env{DEV_ID}) {
        _file_deep_copy 0, $file_src, $file_dest;
        _remove_file_recursively $file_src;
      } else {
        mv $file_src, $file_dest;
      }
    };
    if ($@) {
      unless ($bool_number) {
        say "失败。";
        say STDERR "EE: 恢复\"$file_src\" 时发生致命错误，跳过。\n",
          "\t错误信息: $@";
      }
      next;
    }

    # 然后删除对应的.trashinfo 文件
    my $info_file = _get_trash_absolute_path (\%trash_env, 'info',
                        (basename $file_src).".trashinfo");
    _remove_file_recursively $info_file;

    next
      if 1 == $skip;

    say "完成。"
      unless $bool_number;
    ++$file_number;
  }

  say $file_number
    if $bool_number;

  return 1;
}

# ============================================
# 打印无效文件目录
# ============================================
sub _which_invalid_dir {
  if ($trash_env{TRASH_BACKUP_PATH}) {
    say $trash_env{TRASH_BACKUP_PATH}
  } else {
    say "未知路径。"
  }
}

# ============================================
# 删除所有无效文件
#
# 参数：
# $强制标记
# ============================================
sub _clean_invalid_file ($) {
  my $bool_force = shift;

  if (0 == $bool_force) {
    print '确定要删除所有无效文件吗？(Y/n): ';
    my $answer = getc;
    say '确认询问失败，无效文件未清理。'
      and return 0
      unless 'Y' eq $answer;
  }

  print "正在删除所有无效文件...\t";
  _remove_sub_file_recursively $trash_env{TRASH_BACKUP_PATH};
  say '完成。'
}

# ============================================
# 打印脚本的版本信息
# ============================================
sub _print_version {
  my $version_msg = << 'END_OF_VERSION';
ltrash %s
Copyright (C) 2014-2015 秦凡东  
不提供任何可靠性承诺，如有BUG 请提交Issues：
https://github.com/Arondight/ltrash/issues
END_OF_VERSION

  printf $version_msg, $VERSION;

  exit 0;
}

# ============================================
# 打印帮助
# 当发现有标量参数时首先打印标量
# 函数会在打印完毕后退出程序
#
# 参数:
# $出错信息
# ============================================
sub _print_help ($) {
  my $error_msg = shift;

  say STDERR "EE: $error_msg。"
    if defined $error_msg;

  print << 'END_OF_HELP';

使用方法:
    ltrash [辅助选项]... [动作选项] [文件名|匹配串]...

动作选项:
    -d, --delete            删除文件到回收站
    -E, --Erase             从回收站中彻底删除文件
    -C, --Clean             清空回收站
    -a, --list-all          打印回收站文件的列表
    -s, --search            查找回收站中的文件
    -r, --recover           从回收站中恢复删除的文件
    -v, --version           打印程序版本
    -h, --help              打印帮助
    -m, --man               打印手册
    --which-invalid-dir     打印无效文件存放目录
    --clean-invalid-file    删除所有无效文件

辅助选项：
    -p, --pcre              匹配文件时采用PCRE 正则表达式
    -f, --force             使用默认行为而不进行确认询问
    -l, --link-follow       操作链接指向的目标而非链接本身
    -c, --count-number      只打印处理的文件数量而非具体信息
    -b, --begin-time        起始时间
    -e, --end-time          终止时间
    -t, --type              文件类型
    -n, --min-size          文件大小下限
    -N, --max-size          文件大小上限

时间格式：
    yyyy-mm-dd-hh-mm-ss     年-月-日-时-分-秒
    number[y|m|d|h|M|s]     数值[年|月|日|时|分|秒]
    now                     现在

类型格式：
    any(任意),dir(目录),reg(普通),txt(文本),spt(脚本),
    img(图片),ado(音频),vdo(视频),exe(程序),zip(归档)

大小格式：
    number[b|k|m|g|t]       数值[Byte|KiB|MiB|GiB|TiB]
END_OF_HELP

  exit 1
    if defined $error_msg;

  exit 0;
}

1;

=encoding utf-8

=head1 App::ltrash

 一个回收站模块

=head1 描述

请忘掉这个模块，避免使用它！

=head1 用法

  use App::ltrash;

  # 需要传递完整的命令行参数，一般是@ARGV
  my $trash = App::ltrash->new (@args);

  $trash->run;

  # 用完必须显式销毁
  $trash->DESTORY;

=cut

