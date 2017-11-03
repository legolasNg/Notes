## Swoole

swoole使用底层的socket调用

fork()      =>      多进程
pthread     =>      多线程

eventfd     =>      线程/进程间消息通知
timerfd     =>      定时器
signalfd    =>      信号的屏蔽和处理 (避免线程和进程被信号打断，系统调用restart)

master进程    =>      事件循环使用select/poll(主进程中的文件描述符只有几个)
reactor线程   =>      事件循环使用epoll/kqueue
worker进程    =>      事件循环使用epoll/kqueue
task进程      =>      没有事件循环，进程会循环阻塞读取管道

### Reactor线程

swoole的master进程是一个多线程程序，其中有一个很重要的线程--reactor线程。真正处理tcp连接，收发数据。
swoole的master进程Accept新连接后，将这个连接分配给一个固定的reactor线程，并由这个线程负责监听此socket。

在socket可读时，读取数据并进行协议解析，将请求投递到worker进程。
在socket可写时，将数据发送给TCP客户端

### Manager进程

worker/task进程都是由Manager进程fork并管理

- 子进程结束运行，manager进程负责回收此子进程，避免成为zombie进程，并创建新的子进程
- 服务器stop，manager进程将发送信号给所有子进程，通知子进程关闭服务
- 服务器reload，manager进程将逐个关闭/重启子进程

> 由manager进程而不是master进程fork和管理，主要原因是master进程是多线程，不能安全的执行fork

### Worker进程

当worker进程异常退出(发生php致命错误、被其它程序误杀、达到max_request次数后正常退出)，master进程会重新拉起新的worker进程。
worker可是同步也可以是异步

### task进程



### 跟踪和调试

查看进程的poll系统调用

````
strace -f -p [pid]
````
