# 关于

程序的目的是为了方便在虚拟终端下管理回收站，可以和几乎所有桌面环境
（Xfce, KDE, Gnome...）的回收站机制相配合。

程序做的比桌面环境的文件管理器方便的地方有：

1. 同时提供通配符和PCRE 正则表达式匹配
2. 为了辅助匹配提供了完善的时间控制机制，支持时间偏移量的使用
3. 支持文件的类型匹配，方便在某一类文件中快速查询
4. 支持通过指定文件大小范围进行更准确的筛选

如有漏洞请先查看[Changes][id_Changes] 确认漏洞是否已经修复，
未被修复则请提交[Issues][id_Issues]。

[id_Changes]: Changes "点此阅读Changes"
[id_Issues]: https://github.com/Arondight/ltrash/issues "点此提交问题"

程序的初衷只是自用，作者不会对程序在你的机器上造成任何非期望行为负责。

# 安装

1. 获取该项目

    `git clone https://github.com/Arondight/ltrash.git /tmp/ltrash`

2. 根据**INSTALL**文件进行安装

    `cd /tmp/ltrash && less INSTALL`

    你可以在线查看[INSTALL][id_INSTALL]。

[id_INSTALL]: INSTALL "点此阅读INSTALL"

# 示例

+ 删除文件file、目录dir 和软链接link 指向的目标文件

    `ltrash -l -d file dir link`

+ 删除当前目录下所有大小不足3MiB 的音频文件

    `ltrash -N 3m -t ado -d *`

+ 使用PCRE 正则表达式匹配并恢复文件"saber" 和"saber lily"

    `ltrash -p -r 'saber(\hlily)?'`

+ 查询删除日期为1987 年6 月5 日至今、大小在500Byte 到500KiB 之间的文本文件

    `ltrash -b 1987/6/5 -n 500 -N 500k -t txt -a`

+ 恢复2014 年7 月到3 天前删除的大小超过2MiB 的音频文件

    `ltrash -b 2014-7 -e 3d -n 2m -t ado -r '*'`

+ 查询半小时前至今删除的隐藏图片文件的数量

    `ltrash -b 0.5h -t img -c -s '.*'`

+ 询问是否清空回收站

    `ltrash -C`

    `ltrash -E '*'`

    `ltrash -p -E '([delete])*(any)*[thing]*.?'`

