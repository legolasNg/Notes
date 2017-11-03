
## 安装Xhprof(PHP7版本)

```bash
$ git clone https://github.com/Yaoguais/phpng-xhprof.git
$ cd phpng-xhprof
# 如果没有phpize命令，需要安装php-devel
$ phpize
# 如果php是手动编译，需要给./configure指定--with-php-config=[php-path]参数
$ ./configure
# 使用make test可以安装测试用例
$ make clean && make && sudo make install
```

## 修改php配置

```
[xhprof]
extension=phpng_xhprof.so
xhprof.output_dir=/home/legolas/xhprof
```

## 使用

添加profile代码

```php
xhprof_enable();
// your code
...
file_put_contents((ini_get('xhprof.output_dir') ? : '/tmp') . '/' . uniqid() . '.xhprof.xhprof', serialize(xhprof_disable()));
```
