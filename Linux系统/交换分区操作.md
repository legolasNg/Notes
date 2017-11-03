
# Swap

Swap，交换分区），类似于Windows的虚拟内存。
当内存不足的时候，把一部分硬盘空间虚拟成内存使用,从而解决内存容量不足的情况。

## 添加一个交换分区

格式化swap分区,并且挂载

````
# fdisk /dev/sdx
# mkswap /dev/sdx
# swapon /dev/sdx
````

修改/etc/fstab配置便于开机自动挂载，加入

````
/dev/sdx    swap    swap    defaults    0 0
````

查看挂载情况

````
# swapon -s
# free -m
# cat /pro/swaps
````

关闭swap

````
# swapoff /dev/sdx
````

## 添加一个交换文件

创建用于交换分区的文件

````
# dd if=/dev/zero of=[swap_path] bs=[block_size] count=[block_number]
````

格式化

````
# mkswap /mnt/swap
# chmod 600 /mnt/swap
````

激活交换分区文件

````
# swapon /mnt/swap
````

编辑/etc/fstab配置便于开机自动挂载，加入

````
/mnt/swap   swap    swap    default     0 0
````

查看挂载情况

````
# swapon -s
# free -m
# cat /pro/swaps
````

关闭swap

````
# swapoff /mnt/swap
````
