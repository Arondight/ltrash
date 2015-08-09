# =========================================== #
# 如有BUG 请提交Issues                        #
# https://github.com/Arondight/ltrash/issues  #
#                                             #
#         Copyright (C) 2014-2015 秦凡东      #
# =========================================== #
package App::ltrash::_file_type;

our $VERSION = '0.12';

use strict;
use warnings;
use 5.010;
use Time::Local;
use Exporter qw (import);

our @EXPORT = qw {
  _get_type
  _file_type
  _file_mimeinfo
};

use subs qw {
  _get_type
  _file_type
  _file_mimeinfo
};

# ============================================
# 返回文件类型
#
# 参数:
# $类型缩写
# ============================================
sub _get_type ($) {
  my $type = shift;

  my %type_name = qw {
    reg   普通
    dir   目录
    ima   图片
    img   图片
    tex   文本
    txt   文本
    aud   音频
    ado   音频
    vid   视频
    vdo   视频
    sci   脚本
    spt   脚本
    scp   脚本
    scpt  脚本
    exe   程序
    arc   归档
    zip   归档
    any   任何
  };

  die "DIE: 期望一个类型但没有得到。"
    unless defined $type;

  # 英文组合，返回缩写对应的类型名
  # 否则返回参数或者结束程序
  if ($type =~ /^\w+$/) {
    for (keys %type_name) {
      return $type_name{$_}
        if $type =~ /^$_/i;
    }
  } else {
    my %type_table = reverse %type_name;
    return $type
      if exists $type_table{$type};
  }

  printf STDERR "EE: 未知的类型$type。\n"
    and exit 1;
}

# ============================================
# 确定参数文件的类型
#
# 参数:
# $文件绝对路径
# ============================================
sub _file_type ($) {
  my $file = shift;

  say STDERR "EE: 文件\"$file\" 不存在。"
    and return 0
    unless -e $file or -l $file;

  SWITCH: {
    -l $file and do { return '链接'; };   # 必须最先检查链接
    -d $file and do { return '目录'; };
    -p $file and do { return '管道'; };
    -S $file and do { return '套接字'; };
    -b $file and do { return '块'; };
    -c $file and do { return '字符'; };
    -f $file and do { return _file_mimeinfo $file; };   # 尽量避免不必要的开销
    DEFAULT: { return '未知'; }
  }

  return 0;
}

# ============================================
# 根据魔数和后缀返回普通文件的类型
#
# 参数:
# $文件绝对路径
# ============================================
sub _file_mimeinfo ($) {
  my ($file, $data) = shift;
  my @image_file_magic = (
    "^P[123456]", "^IIN1", "^MM\x00\x2a", "^II\x2a\x00", "^\x89PNG", "^.PNG",
    "^GIF8", "^\361\0\100\273", "^\xff\xd8", "^hsi1", "^BM", "^IC", "^v/1",
    "^\x59\xa6\x6a\x95", "^\033E\033", "^Bitmapfile", "^IMGfile", "^~BK",
    "^\x00\x00\x00\x0c\x6a\x50\x20\x20\x0d\x0a", "^8BPS", "^\x42\x50\x47\xfb",
    "^I\ I", "^II\\*", "^LA:", "^MM.(\\*|\\+)", "^SDPX", "^XPDS", "^\ gimp xcf",
    "^\x80\x2a\x5f\xd7", "^\x97\x4a\x42\x32\x0d\x0a\x1a\x0a", "^´nhd",
    "^\xff\xd8\xff\xe1.{2}Exif\x00", "^\xff\xd8\xff\xe8.{2}SPIFF\x00",
  );
  my @image_file_suffix = (
    "\\.jpe?g\$", "\\.giff?\$", "\\.w?bmp\$", "\\.cur\$", "\\.pcx\$",
    "\\.p[cs]d\$", "\\.mac\$", "\\.tiff?\$", "\\.dwg\$", "\\.eps\$", "\\.ico\$",
    "\\.pm5\$", "\\.tga\$", "\\.jp2\$", "\\.l[dw]f\$", "\\.sgi\$", "\\.fax\$",
    "\\.d2am\$", "\\.jb[2f]\$", "\\.bw\$", "\\.psd\$", "\\.dib\$",  "\\.bpg\$",
    "\\.dst\$", "\\.dpx\$", "\\.xcf\$", "\\.exr\$", "\\.psp\$", "\\.cin\$",
    "\\.tib\$",
  );
  my @video_file_magic = (
    "^\x00\x00\x01\xb3", "^\x00\x00\x01\xba", "^MOVI", "^.{4}moov",
    "^.{4}mdat", "^.{8}mp42", "^.{12}mdat", "^.{36}mdat", "^\x30\x26\xb2\x75",
    "^.{8}AVI", "^.{1}RMF", "^.{4}ftyp(?!M4A)", "^\x1a\x45\xdf\xa3", "^.REC",
    "^\x30\x26\xb2\x75\x8e\x66\xcf\x11\xa6\xd9\x00\xaa\x00\x62\xce\x6c",
    "^FLV", "^Genetec\ Omnicast", "^RIFF.{4}(?!(CDDA|WAVE)fmt)", "^THP",
  );
  my @video_file_suffix = (
    "\\.mpe?g\$", "\\.avi\$", "\\.rm(vb)?\$", "\\.moo?v\$", "\\.msl\$",
    "\\.wm[av]\$", "\\.as[xf]\$", "\\.dat\$", "\\.wvx\$", "\\.mp[aev]\$",
    "\\.qt\$", "\\.[dg]l\$", "\\.fl[ic]\$", "\\.movie\$", "\\.f[l4]v\$",
    "\\.m4v\$", "\\.vob\$", "\\.webm\$", "\\.ivr\$", "\\.asf\$", "\\.g64\$",
    "\\.dat\$", "\\.4xm\$", "\\.thp\$", "\\.og[gv]\$"
  );
  my @audio_file_magic = (
    "^\xff\xf0", "^ASF\ ", "^\<ASX", "^\<asx", "^\.snd", "^MThd", "^CTMF",
    "^SBI", "^Creative\ Voice\ File", "^\x4e\x54\x52\x4b", "^.{8}WAVE", "^EMOD",
    "^\x2e\x72\x61\xfd", "^MTM", "^if", "^FAR", "^MAS_U", "^#!AMR", "^.{44}SCRM",
    "^GF1PATCH110\0ID\#000002\0", "^GF1PATCH100\0ID\#000002\0", "^JN", "^UN05",
    "^Extended\ Module\:", "^.{21}\!SCREAM\!", "^.{1080}M\.K\.", "^\xff\xf9",
    "^.{1080}M\!K\!", "^.{1080}FLT4", "^.{1080}4CHN", "^.{1080}6CHN", "^\x2eRMF",
    "^.{1080}8CHN", "^.{1080}CD81", "^.{1080}OKTA", "^.{1080}16CN", "^#!SILK",
    "^.{1080}32CN", "^TOC", "^\xff\xfa", "^ID3", "^.{4}ftypM4A", "^\x2eray",
    "^FORM\x00", "^RIFF.{4}(CDDA|WAVE)fmt", "^SCH1", "^caff", "^dns\x2e",
    "^fLaC\x00\x00\x00\"", "^\x80\x00\x00\x20\x03\x12\x04", "^\xff\xfa",
  );
  my @audio_file_suffix = (
    "\\.aiff?\$", "\\.au\$", "\\.mp[123]\$", "\\.as[xt]\$", "\\.m3u\$",
    "\\.pls\$", "\\.mlv\$", "\\.m[4p]a\$", "\\.ram?\$", "\\.snd\$", "\\.wav\$",
    "\\.voc\$", "\\.ins\$", "\\.cda\$", "\\.mid\$", "\\.c[am]f\$", "\\.rmi\$",
    "\\.rcp\$", "\\.mod\$", "\\.s3m\$", "\\.xm\$", "\\.mtm\$", "\\.[fk]ar\$",
    "\\.it\$", "\\.amr\$", "\\.sil\$", "\\.dax\$", "\\.adx\$", "\\.koz\$",
    "\\.flac\$", "\\.aac\$",
  );
  my @script_file_magic = (
    "^\#\!\ *\/",
  );
  my @script_file_suffix = (
    "\\.p[lym]\$", "\\.rbw?\$", "\\.jsp\$", "\\.php\$", "\\.vb[se]\$",
    "\\.(ba|z|c|tc|k)?sh\$", "\\.bat\$", "\\.ps1\$",
  );
  my @executable_file_magic = (
    "^MZ", "^.{1}ELF",
  );
  # my @executable_file_suffix = (
  # "不需要这个数组"
  # );
  my @archive_file_magic = (
    "^\xbe\xba\xfe\xca", "^\x00\x01\x42\x44", "^\x00\x01\x44\x54", "^xar!",
    "^\x50\x4b((\x03\x04)|(\x05\x06)|(\x07\x08))", "^Rar!", "^(.{257})?ustar",
    "^\x00\x01\x42(\x41|\x44)", "^\x1a\x0b", "^\x1f\x8b\x08", "^\x21\x12",
    "^\x1f((\x9d)|(\xa0))", "^\\(This\ file\ mustbe\ converted\ with\ BinHex",
    "^.{2}-1h", "^BZh", "^JARCS", "^MAR", "^MAr", "^PACK", "^.{30}PKLITE",
    "^SIT!", "^StuffIt (c)1997-", "^ZOO", "^\x5f\x27\xa8\x89", "^\x60\xea",
    "^CD001", "^\xfd\x37\x7a\x58\x5a\x00", "^CISO", "^DAX", "^ENTRYVCD.{7}X",
    # WinZip 格式判断代价太大只用后缀名判断
    # 如需通过魔数判断，修改下个read 函数第三个参数大于29158 才有意义
    # "^.{29152}WinZip",
    );
  my @archive_file_suffix = (
    "\\.tar(\.(([gx]z)|(bz2?)))?\$", "\\.t?[gx]z\$", "\\.[rx]ar\$", "\\.zip\$",
    "\\.7z\$", "\\.t?bz2?\$", "\\.sea\$", "\\.[ad]ba\$", "\\\.tda\$", "\\.jar\$",
    "\\.apk\$", "\\.pak\$", "\\.arc\$", "\\.hqx\$", "\\.l(ha|zh)\$", "\\.mar\$",
    "\\.epub\$", "\\.sit\$", "\\.zoo\$", "\\.arj\$", "\\.[ci]so\$", "\\.dzx\$",
    "\\.vcd\$", "\\.rpm\$", "\\.deb\$",
  );

  my $file_fh;
  unless (open $file_fh, '<', $file) {
    say STDERR "WW：无法读取文件\"$file\"";
    return '未知';
  }
  read $file_fh, $data, 2*1024, 0;
  close $file_fh;

  # 判断文件类型并返回，必须先判断文本文件
  if (-T $file) {
    return _get_type '脚本'
      if map { $file =~ /$_/i } @script_file_suffix
          or map { $data =~ /$_/ } @script_file_magic;
    return _get_type '文本';
  } elsif (map { $data =~ /$_/ } @image_file_magic) {
    return _get_type '图片';
  } elsif (map { $data =~ /$_/ } @video_file_magic) {
    return _get_type '视频';
  } elsif (map { $data =~ /$_/ } @audio_file_magic) {
    return _get_type '音频';
  } elsif (map { $data =~ /$_/ } @executable_file_magic) {
    return _get_type '程序';
  } elsif (map { $data =~ /$_/ } @archive_file_magic) {
    return _get_type '归档';
  } else {
    return _get_type '图片'
      if map { $file =~ /$_/i } @image_file_suffix;
    return _get_type '视频'
      if map { $file =~ /$_/i } @video_file_suffix;
    return _get_type '音频'
      if map { $file =~ /$_/i } @audio_file_suffix;
    return _get_type '归档'
      if map { $file =~ /$_/i } @archive_file_suffix;
    return _get_type '普通';
  }
}

1;

=encoding utf-8

=head1 名称

App::ltrash::_file_type

=head1 描述

得到文件的类型，结合魔数和后缀名进行判断。

=head1 用法

  use App::ltrash::_file_type;

  $file = '/path/to/file';
  $file_type = _file_type $file;

=cut

