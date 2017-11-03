# 磁盘操作

## 1、磁盘分区

查看主机下的磁盘设备
````
# fdisk -l
````
对指定磁盘进行分区 => xvdb1
````
# fdisk /dev/xvdb
````

## 2、磁盘格式化
设置文件系统
````
# mkfs.ext4 /dev/xvdb1
````

## 3、磁盘挂载
创建挂载点目录，并挂载
````
# mkdir /data
# mount /dev/xvdb1 /data
````

## 4、磁盘开机自动挂载
查找磁盘设备的uuid
````
# blkid /dev/xvdb1
或者
# ls -l /dev/disk/by-uuid/
````
编辑/etc/fstab
````
#device UUID                    mount point     filesystem      mount options   dump    fsck
UUID=dbbdde81-e21b-402e-aaca-a1ec441a12fb       /data   ext4    defaults,barrier=0      0 0
````

## 5、磁盘空间占用

 > df [OPTION]... [FILE]...

参数列表
````
-a 全部文件系统列表
-l 只显示本地文件系统

-h 方便阅读方式显示
-T 文件系统类型
-i 显示inode信息

-H 等于“-h”，但是计算式，1K=1000，而不是1K=1024
-k 区块为1024字节
-m 区块为1048576字节

--no-sync 忽略 sync 命令
-P 输出格式为POSIX
--sync 在取得磁盘信息前，先执行sync命令
````

 查看磁盘占用
 ````
 # df -h
 ````

## 6、磁盘空间使用

 > du [OPTION]... [FILE]...
 > du [OPTION]... --files0-from=F

````
-a或-all  显示目录中个别文件的大小
-c或--total  除了显示个别目录或文件的大小外，同时也显示所有目录或文件的总和
-S或--separate-dirs   显示个别目录的大小时，并不含其子目录的大小
-L<符号链接>或--dereference<符号链接> 显示选项中所指定符号链接的源文件大小

-b或-bytes  显示目录或文件大小时，以byte为单位
-k或--kilobytes  以KB为单位输出
-m或--megabytes  以MB为单位输出
-H或--si  与-h参数相同，但是K，M，G是以1000为换算单位

-s或--summarize  仅显示总计，只列出最后加总的值
-h或--human-readable  以K，M，G为单位，提高信息的可读性

-x或--one-file-xystem  以一开始处理时的文件系统为准，若遇上其它不同的文件系统目录则略过
--exclude=<目录或文件>         略过指定的目录或文件

-X<文件>或--exclude-from=<文件>  在<文件>指定目录或文件
-D或--dereference-args   显示指定符号链接的源文件大小
-l或--count-links   重复计算硬件链接的文件
````

显示某个目录的占用空间大小
````
# du -sh /data
````
