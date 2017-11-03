## 安装Xdebug

```bash
$ git clone https://github.com/xdebug/xdebug
$ cd xdebug
# 如果没有phpize命令，需要安装php-devel
$ phpize
# 如果php是手动编译，需要给./configure指定--with-php-config=[php-path]参数
$ ./configure --enable-xdebug
$ make clean && make && sudo make install
```

## 修改php配置

```
[xdebug]
zend_extension=xdebug.so
xdebug.profiler_enable=on
xdebug.trace_output_dir="/home/legolas/xdebug"
xdebug.profiler_output_dir="/home/legolas/xdebug"
```

## 使用

```php
```
