## [SystemTap](https://sourceware.org/systemtap/wiki)

SystemTap是监控和跟踪运行中的linux内核操作的动态方法，不需要使用工具构建一个特殊的内核，而是允许在运行时动态地使用该工具。

### 1.安装

```bash
# 需要开启debuginfo仓库(kernel-debuginfo和kernel-debuginfo-common需要)
sudo yum-config-manager --enable base-debuginfo (centos发行版)
sudo dnf config-manager --set-enabled fedora-debuginfo (fedora发行版)
# 安装内核开发包和调试包(提供调试内核所需的符号表)，软件包的版本要和内核版本一致
sudo yum install kernel-debuginfo kernel-debuginfo-common-x86_64
# 编译内核模块所需的内核头文件及模块配置信息(debian系的包名叫linux-headers-generic)
sudo yum install kernel-devel
# 提供分析调试信息的库函数，提供libdwfl支持
sudo yum install elfutils
# 安装SystemTap
sudo yum install systemtap
```

> **注意事项：** 如果linux系统内核低于3.5，内核没有提供utrace/uprobes用户态支持，需要打上utrace补丁。内核版本3.5及以上版本，kernel已经默认包含了uprobes机制，不需要utrace补丁。

### 2.检查是否安装成功

运行一下命令`sudo stap -v -e 'probe vfs.read {printf("read performed\n"); exit()}'`，会得到一下类似结果。

```
Pass 1: parsed user script and 476 library scripts using 273160virt/73848res/7436shr/66648data kb, in 190usr/140sys/703real ms.
Pass 2: analyzed script: 1 probe, 1 function, 7 embeds, 0 globals using 462484virt/264900res/9048shr/255972data kb, in 2460usr/2780sys/13806real ms.
Pass 3: translated to C into "/tmp/stapu3n0C1/stap_1fa2fa75b22d3e1b75c4c3c2d4cdc2fa_2583_src.c" using 462484virt/265092res/9240shr/255972data kb, in 0usr/0sys/4real ms.
Pass 4: compiled C into "stap_1fa2fa75b22d3e1b75c4c3c2d4cdc2fa_2583.ko" in 7060usr/1730sys/10218real ms.
Pass 5: starting run.
read performed
Pass 5: run completed in 20usr/280sys/726real ms.
```

或者运行`sudo stap -c df -e 'probe syscall.* { if (target()==pid()) log(name." ".argstr) }'`

#### SystemTap流程

SystemTap用于探测运行的内核的两种方法：Kprobes和返回探针。但是理解内核最关键要素是 **内核的映射** ，提供符号信息(函数、变量和它们的地址)，有了内核映射之后，就可以解决任何符号的地址，已经修改探针的行为。

SystemTap基本流程涉及到3个交互应用程序和5个阶段：

- pass1：script translation，将脚本解析为解析树
- pass2：script elaboration，细化当前运行内核的符号信息解析符号
- pass3：script translation，将解析树转换为C源码，并使用解析后的信息和tapset脚本(SystemTap定义的库) -- stap_XXXX.c
- pass4：module build，构造使用本地内核模块构建进程的内核模块 -- stap_XXXX.ko
- pass5：Module install/Monitor => Module unload/Cleanup，将模块安装到内核并将输出发送到stdout；如果按下"Ctrl+C"或者脚本退出，将执行清除进程(卸载模块并退出所有相关程序)

pass1到pass4由`stap`程序完成，pass5阶段由`staprun`和`stapio`完成。SystemTap具有缓存脚本转换的能力，如果安装后的脚本没有更改，可以使用现有的模块，而不需要重新构建模块。

### 3.编写SystemTap脚本

systemtap脚本由探针和触发探针时需要执行的代码块组成。探针有许多预定义模式，下表列举几种探针类型(包括调用内核函数和从内核函数返回)：

#### 探针类型

| 探针类型                                   | 说明                                                     |
| :-------------                            | :-------------                                           |
| begin                                     | 在脚本开始时触发                                          |
| end                                       | 在脚本结束时触发                                          |
| kernel.function("sys_sync")               | 调用sys_sync时触发                                        |
| kernel.function("sys_sync").call          | 调用sys_sync时触发                                        |
| kernel.function("sys_sync").return        | 返回sys_sync时触发                                        |
| kernel.syscall.*                          | 进行任何系统调用时触发                                     |
| kernel.function("*@kernel/fork.c:934")    | 到达fork.c的934行时触发                                   |
| module("ext3").function("ext3_file_write")| 调用ext3的write函数时触发                                 |
| timer.jiffies(1000)                       | 每隔1000个内核jiffy触发一次                                |
| timer.ms(200).randomize(50)               | 每隔200毫秒触发一次，带有线性分布的随机附加时间(-50到+50)    |

还可以声明可以被探针调用的函数，尤其是供多个探针调用的通用函数。支持递归到给定深度。

#### 变量和类型

允许定义多种类型的变量，不需要使用类型声明(类型是从上下文推断得出)。

- number(64位有符号整型)
- interger(64位)
- string
- literal(字面量，可以是integer或string)
- 关联数组(用哈希表实现，需要声明数组大小，如果不指定数组大小，默认为MAXMAPENTRIES--2048；关联数组必须全局，不能在探测点处理函数内部定义；数组索引最多有9个，用逗号隔开，可以是字符串或数字；元素的数据类型：数值、字符串、统计类型)
- 统计类型(statistics aggregates，用于统计全局变量，操作符是`<<<`。统计类型变量只能用特定函数操作，@count()、@sum()、@min()、@max()、@avg())

```stap
# 使用多个索引定位数组元素
foo[4, "hello"]
# 判断元素是否存在
if ([4, "hello"] in foo) {}
# 删除元素
delete foo["hello"]
delete foo  #删除全部元素
# 删除变量
delete var  #如果变量是数值类型，重置为0；如果是字符串类型，重置为''

global_var <<< b    # 相当于C语言中 global_var += b
@count(global_var)  # 统计操作的操作次数
@sum(global_var)    # 统计操作的操作数总和
@min(global_var)    # 统计操作的操作数最小值
@max(global_var)    # 统计操作的操作数最大值
@avg(global_var)    # 统计操作的操作数平均值
```

#### 表达式

- 和C类似的必要操作符，算术操作符、二进制操作符、赋值操作符、指针解引用
- 简化C操作，字符串连接(`.`)、关联数组元素、合并操作符

#### 语言元素

- SystemTap中每个探针只能执行1000条语句(数量可配置)。
- 语句结尾不用结束符，分号";"表示空语句，函数时候"{}"括起来。
- next语句用于提前退出探测函数
- 注释可用`#`(shell风格)、`/**/`(C语言风格)和`//`(C++风格)

| 语句                          | 描述                          |
| :-------------                | :-------------                |
| if (exp) {} else {}           | 标准的if-then-else语句         |
| for (exp1; exp2; exp3) {}     | for循环                       |
| while (exp) {}                | 标准的while循环                |
| do {} while ()                | do-while循环                  |
| break                         | 退出迭代                       |
| continue                      | 继续迭代                       |
| next                          | 从探针返回                     |
| return                        | 从函数返回一个表达式            |
| foreach (VAR in ARRAY) {}     | 迭代一个数组，将当前key赋值给VAR |

```stap
# 遍历 / 迭代 (可以使用break/continue，遍历期间不允许修改数组)
foreach (VAR in ARRAY) {}                   # 按值遍历，VAR为元素值
foreach ([VAR1, VAR2...] in ARRAY) {}       # 按索引遍历
foreach (VAR = [VAR1, VAR2...] in ARRAY) {} # 同时得到索引和元素值
```

#### [内部函数](https://linux.die.net/man/5/stapfuncs)

SystemTap提供很多内部函数，可以提供当前上下文的额外信息，或者提供对调用堆栈和register寄存器的访问。

- caller()：返回当前调用函数
- tid()：返回当前线程id
- pid()：返回进程id
- uid()：返回当前用户id
- execname()：返回当前进程名
- cpu()：返回当前cpu编号
- gettimeofday_s()：返回当前时间戳
- get_cycles()：返回硬件时钟计数器的快照
- pp()：返回当前被执行的探测点的文字描述
- probefunc()：返回放置此探针的函数名
- $$vars：打印作用域内局部变量的格式化列表
- print_backstack()：打印内核空间调用栈
- print_ubackstack()：打印用户空间调用栈
- $$vars 包含所有函数参数、局部变量的字符串
- $$params 包含所有函数参数的字符串
- $$locals 包含所有局部变量的字符串
- $$return：表示函数返回值
- thread_indent()：返回关于该线程的一个带缩进的字符串()

#### 内置探测点(DWARF probes)

安装debuginfo之后才可以使用，内置的探测点类型：

- kernel.function(PATTERN)：在函数入口放置探测点，可以获取函数参数$PARM
- kernel.function(PATTERN).return：在函数返回处放置探测点，可以获取函数的返回值$return，以及可能被修改的函数参数$PARM
- kernel.function(PATTERN).call：取补集，取不符合条件的函数
- kernel.function(PATTERN).inline：只选择符合条件的内联函数，内联函数不能使用.return
- kernel.function(PATTERN).exported：只选择导出的函数
- module(MPATTERN).function(PATTERN)
- module(MPATTERN).function(PATTERN).return
- module(MPATTERN).function(PATTERN).call
- module(MPATTERN).function(PATTERN).inline
- kernel.statement(PATTERN)
- kernel.statement(ADDRESS).absolute
- module(MPATTERN).statement(PATTERN)

```satp
# 引用所有函数名含有init或者exit的内核函数
kernel.function("*init*"), kernel.function("*exit*")
# 引用"kernel/time.c"文件240内的所有函数
kernel.function("*@kernel/time.c:240")
# 引用ext模块的所有函数
module("ext3").function("*")
# 引用"kernel/time.c"文件第296行语句
kernel.statement("*@kernel/time.c:296")
# 引用"fs/bio.c"文件中bio_init函数第三行的语句
kernel.statement("bio_init@fs/bio.c+3")
```

部分在编译单元内可见的变量，比如函数参数、局部变量或全局变量，在探测点处理函数中同样可见。变量的引用有两种风格：

- "$+变量名"
    + `$varname`：引用变量varname
    + `$varname->field`：引用结构的成员变量
    + `$varname[N]`：引用数组的元素
    + `&$varname`：变量的地址
- "@var(变量名)"
    + `@var("varname")`：引用变量varname
    + `@var("varname@src/file.c")`：引用"src/file.c"在被编译时的全局变量varname
    + `@var("varname@file.c")->field`：引用结构的成员变量
    + `@var("varname@file.c")[N]`：引用数组元素
    + `&@var("var@file.c")`：变量的地址

```
$var$       一个包含基本类型值的变量
$var$$      一个包含嵌套类型值的变量
```

#### 非内置探测点(DWARF-less probe)

当目标内核或者模块缺少调试信息，虽然不能使用内置的探测点，但是仍然可以使用kprobe来探测函数的入口点和退出点(不能使用通配符)。此时不能使用"$+变量名"来获取函数参数和局部变量的值。

- kprobe.function(FUNCTION)
- kprobe.function(FUNCTION).return
- kprobe.module(NAME).function(FUNCTION)
- kprobe.module(NAME).function(FUNCTION).return
- kprobe.statement(ADDRESS).absolute

但是SystemTap仍然提供了一种访问参数的办法：当函数因为被探测而停滞在进入点时，可以使用编号来引用它的参数。例如被探测函数`ssize_t sys_read(unsigned int fd, char __user *buf, size_t count)`，可以使用unit_arg(1)、pointer_arg(2)、ulong_arg(2)来获取fd、buf和count的值。

此类探测器虽然不支持$return，但可以通过调用returnval()来获取寄存器的值(函数返回值通常保存在寄存器中)，也可以调用returnstr()来获取返回值的字符串形式。在处理函数代码里面，可以调用register('regname')来获取函数被调用时特定CPU寄存器的值。

#### 用户空间

SystemTap探测用户空间进程需要utrace支持，内核3.5版本以上默认支持，低于3.5版本需要打utrace补丁。

- process.begin 进程创建时
    + process("PATH").begin
    + process(PID).begin
- process.thread.begin 线程创建时
    + process("PATH").thread.begin
    + process(PID).thread.begin
- process.end 进程结束时
    + process("PATH").end
    + process(PID).end
- process.thread.end 线程结束时
    + process("PATH").thread.end
    + process(PID).thread.end
- process.syscall 系统调用开始
    + process("PATH").syscall
    + process(PID).syscall
- process.syscall.return 系统调用返回
    + process("PATH").syscall.return
    + process(PID).syscall.return
- process(PATTERN).

#### 条件编译

语法`%( CONDITION %? TRUE-TOKENS %)`或者`%( CONDITION %? TRUE-TOKENS %: FALSE-TOKENS %)`，编译条件可以是:

- `@defined($var)`：检查变量是否可用
- `kernel_v > "3.10.0"`：比较内核版本号
- `kernel_vr == "3.10.0-327.22.2.el7.x86_64"`：比较内核版本号(包括后缀)
- `arch == "x86_64"`：比较CPU架构

```stap
%( CONFIG_UTRACE == 'y' %?
    do something...
%)
```

#### 语言安全性

1. 时间限制：探测点处理函数有执行时间限制，占用太多时间会在脚本转换为C语言时报错。每个探测点的处理函数只能执行1000条语句(数量限制可配置)
2. 动态内存分配：探测点处理函数中不允许动态分配内存
3. 锁：多个探测点处理函数抢占一个全局变量锁时，某几个探测点处理函数可能会超时，被放弃执行。(访问全局变量时会加锁，防止它被并发修改)
4. bug：内核中少数对时间非常敏感的地方(上下文切换、中断处理)，不能设置探测点
5. 修改限制：通过命令行的`-D`参数可以修改默认的一些限制。
    - MAXNESTING：函数递归最大层数，默认是10
    - MAXSTRINGLEN：字符串最大长度，32位机器上是256byte，其他机器上是512byte
    - MAXTRYLOCK：在可能死锁或者跳过探测前，等待全局变量锁时重复的最大次数，默认是1000
    - MAXACTION：任何单个探测点命中时，能执行的最大语句数，默认是1000
    - MAXMAPENTRIES：在声明数组时为指定数组大小，数组的最大size，默认是2048
    - MAXERRORS：触发退出前的最大软错误数量，默认是0
    - MAXSKIPPED：触发退出前，跳过可重入的探测最大数量，默认是100
    - MINSTACKSPACE：为了运行探测处理程序，所需的最小可用内核堆栈大小(byte)，默认是1024。为了安全这个数字应足够大，以便满足探测点处理函数的需求

#### 脚本实例

系统调用监控脚本(syslog_profile.stp)

```stap
global syscalllist

probe begin {
    printf("Syslog Monitoring Started (10 seconds)...\n")
}

probe syscall.* {
    if ( execname() == "syslog" ) {
        syscalllist[name] <<< 1
    }
}

probe timer.ms(10000) {
    foreach ( name in syscalllist ) {
        printf("%s = %d\n", name, syscalllist[name] )
    }
    exit()
}
```

使用聚合函数收集网络长度数据(net.stp)

```stap
global recv, xmit

probe begin {
    printf("Starting network capture (Ctl-C to end)\n")
}

probe netdev.receive {
    recv[dev_name, pid(), execname()] <<< length
}

probe netdev.transmit {
    xmit[dev_name, pid(), execname()] <<< length
}

# 按"Ctrl+C"可以触发end事件
probe end {
    printf("\nEnd Capture\n\n")
    printf("Iface Process........ PID.. RcvPktCnt XmtPktCnt\n")
    foreach ( [dev, pid, name] in recv ) {
        recvcount = @count(recv[dev, pid, name])
        xmitcount = @count(xmit[dev, pid, name])
        printf("%5s %-15s %-5d %9d %9d\n", dev, name, pid, recvcount, xmitcount)
    }

    delete recv
    delete xmit
}
```

捕获柱状图数据(nethist.stp)

```stap
global histogram

probe begin {
    printf("Capturing...\n")
}

probe netdev.receive {
    histogram <<< length
}

probe netdev.transmit {
    histogram <<< length
}

probe end {
    printf("\n")
    print( @hist_log(histogram) )
}
```

### 4.执行SystemTap脚本

```bash
stap [OPTIONS] FILENAME [ARGUMENTS]
stap [OPTIONS] - [ARGUMENTS]
stap [OPTIONS] -e SCRIPT [ARGUMENTS]
stap [OPTIONS] -l PROBE [ARGUMENTS]
stap [OPTIONS] -L PROBE [ARGUMENTS]
stap [OPTIONS] --dump-probe-types
stap [OPTIONS] --dump-probe-aliases
stap [OPTIONS] --dump-functions
```

stap是SystemTap工具的前端，接受一种简单的DSL(领域特定语言)编写的探测指令脚本，将这些指令转换为C语言代码，编译C语言代码，并将生成的内核模块加载到正在运行的linux内核或者DynInst用户空间的mutator中，来执行所需要的系统跟踪/探测功能。可以通过脚本文件FILENAME，或者标准输入(使用-替代FILENAME)，或者命令行(-e 脚本内容)。程序将会一直运行直到用户中断，或者脚本自动调用exit()函数，或者一定量的软错误(soft error，高能粒子与硅元素之间相互作用而在半导体中造成的随机、临时的状态改变或瞬变)。

该脚本语言，具有严格类型、表达式、声明自由、面向过程、原型友好，语言风格与awk和C类似。代码允许定义探测点或者系统中的事件，关联上一个处理该探测点或事件的句柄(handler)，这些子程序将会被同步执行。这和GDB中的断点命令列表概念上有点相似。

```
-p NUM：pass NUM次之后运行停止(默认是5次)
-v：提供所有pass的更详细信息，v重复次数越多，输出信息越详细
--vp ABCDE：逐个pass增加详细信息。例如，"002"给pass3增加2个单元的详细信息，
-k：运行结束后不删除临时文件(可以用来检查生成的C代码，或者复用已编译好的内核模块)
-g：gugu模式，启用不安全的专家级结构的解析(允许脚本中嵌入C语言代码)
-P
-u
-w
-W
-b：开启bulk批量模式(每个cpu一个文件)，使用RelayFS文件系统将数据从内核空间传输到用户空间。使用stap-merge将多个cpu数据合并在一起。
-i --interactive
-t
-s
-I
-D NAME=VALUE：添加给定的C预处理指令到模块的makefile文件中，可以用来覆盖一些限制参数
-B NAME=VALUE
-B FLAG
-a ARCH
-modinfo NAME=VALUE
-G NAME=VALUE
-R DIR
-r /DIR
-m MODULE
-d MODULE：将给定模块的符号或展开信息添加到内核对象模块。这使得该模块的符号变得可追溯，即使没有对他们进行显性探测。
--ldd：通过ldd添加所有可能的用户空间共享库的符号或展开信息。配合-d选项，后接被探测的用户空间二进制文件(这样会使探测模块更大)
--all-modules
-o FILE：将标准输出保存到文件中。在批量模式下，每个cpu文件前缀为FILE_，后接CPU编号(-F FILE_cpu)
-c CMD：启动探测，运行CMD命令，并在CMD完成后退出。这和为pid设置target()类似。
-x PID：将target()设置为指定PID，允许编写过滤特定进程的脚本，脚本是独立于pid的声明周期运行的。
-e SCRIPT：在命令行中运行给定脚本
-E SCRIPT：运行指定脚本，该脚本附加在通过"-e"指定的主脚本上，或者附加在脚本文件上。该参数可以重复，用来运行多个脚本，也能用在list模式中(-l/-L)。
-l PROBE：不运行探测脚本，仅仅列举出指定脚本中的所有探测点。pattern可以包含通配符和别名，但不包括逗号分隔的多个探测点。如果没有匹配到，将返回错误码
-L PROBE：和"-l"类似，列举探测点和脚本级别的局部变量
-F：如果没有-o选项，加载模块并开始探测，探测结束后从模块分离；加上-o选项，将作为守护进程在后台运行staprun，并返回pid。
-S size[, N]
-T TIMEOUT
--skip-badvars
--prologue-searching[=WHEN]
--suppress-handler-errors
--compatible VERSION
--check-verison
--clean-cache
--color[=WHEN], colour[=WHEN]
--disable-cache
--poison-cache
--privilege[=stapusr | =stapsys |=stapdev]
--unprivileged
--use-server[=HOSTNAME[:PORT] | =IP_ADDRESS[:PORT] | =CERT_SERIAL]
--use-server-no-error[=yes | =no]
--list-servers[=SERVERS]
--trust-servers[=TRUST_SPEC]
--dump-probe-types
--dump-probe-aliases
--dump-functions
--remote URL
--remote-prefix
--download-debuginfo[=OPTION]
--rlimit-as=NUM
--rlimit-cpu=NUM
--rlimit-nproc=NUM
--rlimit-stack=NUM
--rlimit-fsize=NUM
--sysroot=DIR
--sysenv=VAR=VALUE
--suppress-time-limits
--runtime=MODE
--dyninst
--save-uprobes
--target-namespaces=PID
--monitor=INTERVAL
```

可以从命令行传入两种类型的变量：

- 数值：`$<N>`
- 字符串：`@<N>`

#### 实例

```
$ sudo stap --ldd -d /usr/sbin/nginx --all-modules -D MAXMAPENTRIES=10240 -D MAXACTION=20000 -D MAXTRACE=100 -D MAXSTRINGLEN=4096 -D MAXBACKTRACE=100 -x 28608 test.stp --vp 0001 > test.out
    WARNING: missing unwind/symbol data for module 'stap_9a54dc37d9a977acbffb1a858a84cd1a_26574' 警告可以忽略，不影响火焰图的生成
```

---

## [openresty-systemtap-toolkit](https://github.com/openresty/openresty-systemtap-toolkit)

基于SystemTap的OpenResty实时分析和诊断工具集(不限于nginx,luaJIT,ngx_lua等)，可参考[**中文文档**](https://github.com/openresty/openresty-systemtap-toolkit/blob/master/README-CN.markdown)。

### 1.sample-bt

**on-CPU：** 程序运行在CPU上的时间在所有代码路径上的分布。

该脚本可以用来指定任何用户进程(不仅仅是nginx)，进行用户空间或者内核空间的调用栈(backtraces)采样，或者同时输出两者。它的输出是汇总后的调用栈(按照总数)。

```bash
sample-bt [options]
    -a <args>       将额外的参数传递给stap程序
    -d              输出生成的SystemTap源码
    -h              帮助信息
    -l <count>      仅输出调用频率前<count>份的堆栈信息(默认1024)
    -p <pid>        指定用户进程pid
    -t <seconds>    指定采样时间
    -u              用户空间的堆栈采样
    -k              内核空间的堆栈采样

# 对一个正在运行的nginx进程(pid为12345)，进行5秒的用户空间堆栈采样
./sample-bt -p 12345 -t 5 -u > nginx.bt
# 可以通过指定-k参数，进行内核空间堆栈的采样
./sample-bt -p 12345 -t 5 -k > nginx.bt
# 也可以同时指定-k和-u参数，对用户堆栈和内核堆栈同时进行采样
./sample-bt -p 12345 -t 5 -uk > nginx.bt
# 使用-d参数，将参数传递给stap程序
./sample-bt -p 12345 -t 5 -a '-DMAXACTION=100000'
```

> 采样过程对生产系统产生的开销通常很小。例如，线上linux内核3.6.10，SystemTap版本2.5，我们使用`ab -k2 -c2 -n100000`压测一个执行最简单"hello world"请求，nginx woker进程的吞吐量仅下降11%。

#### systemTap脚本源码

```stap
probe begin {
    warn(sprintf("Tracing %d (/usr/bin/bmon) in user-space only...\n", target()))
}

global bts;
global quit = 0;

probe timer.profile {
    if (pid() == target()) {
        if (!quit) {
            bts[ubacktrace()] <<< 1;
        } else {
            foreach (bt in bts- limit 1024) {
                print_ustack(bt);
                printf("\t%d\n", @count(bts[bt]));
            }
            exit()
        }
    }
}

probe timer.s(5) {
    nstacks = 0
    foreach (bt in bts limit 1) {
        nstacks++
    }
    if (nstacks == 0) {
        warn("No backtraces found. Quitting now...\n")
        exit()
    } else {
        warn("Time's up. Quitting now...(it may take a while)\n")
        quit = 1
    }
}
```

### 2.sample-bt-off-cpu

**off-CPU：** 进程不运行在任何CPU上的时间在所有代码路径上的分布。off-CPU时间一般是因为该进程因为某种原因处于休眠状态，比如在等待某个系统级别的锁，或者被一个非常繁忙的进程调度器(scheduler)强行剥夺。

和`sample-bt`类似，不过该脚本是用于分析特殊用户进程的off-CPU时间。输出结果能和`sample-bt`脚本一样，可以被渲染成火焰图。这类火焰图被称作"off-CPU Flame Graph"，传统火焰图应该被称作"on-CPU Flame Graph"。

- 工具默认采样用户空间的调用栈。在输出数据中，一个逻辑上的调用栈采样对应1微妙的off-CPU时间。
- 默认，off-CPU时间间隔小于4us的会被丢弃掉，可以通过`--min`参数调整这个阈值。
- `-l`选项可以控制输出不同调用栈的上限，默认会dump1024份不同的最热(频繁)调用栈。
- 可以通过`--distr`参数，指定为所有比`--min `这个阈值大的off-CPU时间间隔，输出一个以2为底数的对数柱状图(log2)。
- 可以通过`-k`参数，工具将采样内核空间的调用栈，而不是采样用户空间调用栈。如果想同时对用户空间和内核空间采样，可以同时指定`-u`和`-k`参数。

```bash
sample-bt-off-cpu [optoins]
    -a <args>       将额外的参数传递给stap程序
    -d              输出SystemTap脚本源码
    --distr         只分析消耗的off-CPU时间分布
    -h              帮助信息
    -k              分析内核空间的堆栈调用
    -l <count>      仅输出调用频率前<count>份的堆栈信息(默认1024)
    --min=<us>      跟踪的最小消耗off-CPU时间(默认4us)
    -p <pid>        指定用户进程的pid
    -t <seconds>    指定采样时间(单位为s)
    -u              分析用户空间的堆栈调用

# 分析nginx的worker进程(pid为12345)，对其用户空间堆栈采样5秒
./sample-bt-off-cpu -p 12345 -t 5 > nginx.bt
# 忽略时间间隔短于10us的off-CPU时间，对进程12345进行堆栈采样10s
./sample-bt-off-cpu -p 12345 --min 10 -t 10
# 分析时间间隔大于1us的off-CPU时间，对进程12345进行堆栈采样3s，然后分析off-CPU的时间分布
./sample-bt-off-cpu -p 12345 -t 3 --distr --min=1
    # WARNING: Tracing 10901 (/opt/nginx/sbin/nginx)...
    # Exiting...Please wait...
    # === Off-CPU time distribution (in us) ===
    # min/avg/max: 2/79/1739
    # value |-------------------------------------------------- count
    #     0 |                                                     0
    #     1 |                                                     0
    #     2 |@                                                   10
    #     4 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        259
    #     8 |@@@@@@@                                             44
    #    16 |@@@@@@@@@@                                          62
    #    32 |@@@@@@@@@@@@@                                       79
    #    64 |@@@@@@@                                             43
    #   128 |@@@@@                                               31
    #   256 |@@@                                                 22
    #   512 |@@@                                                 22
    #  1024 |                                                     4
    #  2048 |                                                     0
    #  4096 |                                                     0
    # 可以看到大部分采样落在[4us, 8us)区间的off-CPU时间，最大的off-CPU时间间隔1729us
```

#### SystemTap脚本源码

```stap
global bts
global start_time

global quit = 0;
global found

probe begin {
    warn(sprintf("Tracing %d (/usr/bin/bmon)...\n", target()))
}

probe scheduler.cpu_off {
    if (pid() == target()) {
        if (!quit) {
            start_time[tid()] = gettimeofday_us()
        } else {
            foreach (bt in bts- limit 1024) {
                print_ustack(bt)
                printf("\t%d\n", @sum(bts[bt]))
            }
            exit()
        }
    }
}

probe scheduler.cpu_on {
    if (pid() == target() && !quit) {
        t = tid()
        begin = start_time[t]
        if (begin > 0) {
            elapsed = gettimeofday_us() - begin
            if (elapsed >= 4) {
                bts[ubacktrace()] <<< elapsed
                found = 1
            }
            delete start_time[t]
        }
    }
}

probe timer.s(5) {
    if (!found) {
        warn("No backtraces found. Quitting now...\n")
        exit()
    } else {
        warn("Time's up. Quitting now...(it may take a while)\n")
        quit = 1
    }
}
```

### 3.sample-bt-vfs

和`sample-bt`类似，不过该脚本是用来在VFS(Virtual File System)上采样用户空间调用栈，然后用于渲染成"File I/O Flame Graph"，可以适用于任何开启了debug符号的用户进程(不仅仅是nginx进程)。

这类火焰图可以精确的显示文件I/O的数据量，或者文件I/O延迟在不同的用户空间代码路径的分布。

- 一个调用栈的采样对应的是一个byte的数据量(读或写)
- 默认同时跟踪`vfs_read`和`vfs_write`事件，可以通过指定`-r`参数来跟踪读操作，指定`-w`参数来跟踪写操作
- 不要将该脚本的文件I/O与磁盘I/O混淆，因为只是在VFS级别(高级别)进行探测，系统的页面缓存可以保存很多磁盘读写。
- 指定`latency`参数的情况下，将探测用户进程在VFS的读写操作上的延迟(跟踪内核调用延迟)，一份采样对应1微秒的文件I/O时间(更准确的说是，vfs_read或者vfs_write的调用时间)

```bash
sample-bt-vfs [optoins]
    -a <args>       将额外的参数传递给stap程序
    -d              输出SystemTap脚本源码
    -h              显示帮助信息
    --latency       分析VFS的内核调用的延迟，而不是分析I/O数据量
    -l <count>      仅输出调用频率前<count>份的堆栈信息(默认1024)
    -p <pid>        指定用户进程的pid
    -r              只探测文件的读操作
    -w              只探测文件的写操作
    -t              指定采样时间(单位为s)

# 对用户进程(pid为12345)进行3s的vfs采样
./sample-bt-vfs -p 12345 -t 3 > io.bt
# 对用户进程(pid为12345)进行3s的vfs读操作采样
./sample-bt-vfs -p 12345 -t 3 -r > read.bt
# 对用户进程(pid为12345)进行3s的vfs写操作采样
./sample-bt-vfs -p 12345 -t 3 -w > write.bt
# 指定--latency参数，探测用户进程(pid为12345)在3s内在vfs的读和写操作上消耗的延迟时间
./sample-bt-vfs -p 12345 -t 3 --latency > a.bt
```

#### SystemTap脚本源码

```stap
global bts;
global quit = 0;

probe begin {
    warn(sprintf("Tracing %d (/usr/bin/bmon)...\n", target()))
}

probe vfs.read.return, vfs.write.return {
    if (pid() == target()) {
        if (!quit) {
            if ($return > 0 && devname != "N/A") {
                bts[ubacktrace()] <<< $return
            }
        } else {
            foreach (bt in bts- limit 1024) {
                print_ustack(bt);
                printf("\t%d\n", @sum(bts[bt]))
            }
            exit()
        }
    }
}

probe timer.s(5) {
    nstacks = 0
    foreach (bt in bts limit 10) {
        nstacks++
    }
    if (nstacks == 0) {
        warn(sprintf("Too few backtraces (%d) found. Quitting now...\n", nstacks))
        exit()
    } else {
        warn("Time's up. Quitting now...(it may take a while)\n")
        quit = 1
    }
}
```

### 4.accessed-files

该工具能找出用户进程访问最频繁的文件名，可以在任何用户进程上使用，不仅仅是nginx。

- 通过`-p`参数来指定进行采样分析的用户进程
- 通过`-r`参数来指定分析被读取的文件，通过`-w`参数来指定分析被写入的文件，可以同时使用`-r`和`-w`参数
- 默认通过`Ctrl + C`来终止采样进程，也可以通过`-t`参数来指定采样周期(单位秒)
- 默认将会输出最多10个不同的文件名，可以通过使用`-l`参数来指定输出文件上限

```bash
accessed-files [optoins]
    -a <args>       将额外的参数传递给stap程序
    -d              输出SystemTap脚本源码
    -h              显示帮助信息
    -l <count>      仅输出调用频率前<count>份的堆栈信息(默认1024)
    -p <pid>        指定用户进程的pid
    -r              只探测文件的读操作
    -w              只探测文件的写操作
    -t              指定采样时间(单位为s)

./accessed-files -p 8823 -r
./accessed-files -p 8823 -w
./accessed-files -p 8823 -w -r
./accessed-files -p 8823 -r -t 5
./accessed-files -p 8823 -r -l 20
```

#### SystemTap脚本源码

```stap
global stats
global found

probe begin {
    printf("Tracing %d (/usr/sbin/nginx)...\nHit Ctrl-C to end.\n", target())
}

probe vfs.read.return, vfs.write.return {
    if (pid() == target() && $return > 0) {
        path = __file_filename(file)
        //println(path)
        stats[path] <<< $return
        found++;
    }
}

probe end {
    if (!found) {
        println("No file reads/writes observed so far.")
    } else {
        printf("\n=== Top 10 file reads/writes ===\n")
        i = 0
        foreach (path in stats- limit 10) {
            printf("#%d: %d times, %d bytes reads/writes in file %s.\n", ++i, @count(stats[path]), @sum(stats[path]), path)
        }
    }
}
```

### 5.tcp-accept-queue

该工具是用来对套接字一段时间内的`SYN`队列和`ACK backlog`队列采样分析，可以在任何用户进程上使用，不仅仅是nginx。该工具是实时采样工具。

- 通过使用`--port`参数可以指定套接字监听的本地端口
- `SYN`队列或者`ACK backlog`队列溢出，经常会导致客户端连接超时错误
- 工具默认最多输出10个队列溢出事件，然后立刻退出。可以通过`--limit`参数指定事件报告数的阈值，或者通过`ctrl + C`终止
- 通过`--distr`参数使工具输出队列长度的柱状分布图。可以`ctrl+C`来终止分析，或者通过`--time`来指定实时采样周期(单位秒)
- 即使accept队列不溢出，涉及accept队列的长延时也会导致客户端的超时错误，使用`--latency`参数可以指定分析指定端口的accept队列延迟。可以`ctrl+C`来终止分析，或者通过`--time`来指定实时采样周期(单位秒)

```bash
tcp-accept-queue [optoins]
    -a <args>       将额外的参数传递给stap程序
    -d              输出SystemTap脚本源码
    --distr         仅显示队列长度分布
    -h              显示帮助信息
    --limit=<count> 当<count>个队列溢出事件被发现后退出
    --port=<port>   指定用户进程的pid
    --time=<seconds>输出事件报告和退出前的等待时间(只在--distr时有意义)

# 对指定端口进行accept队列采样
./tcp-accept-queue --port=80
    # WARNING: Tracing SYN & ACK backlog queue overflows on the listening port 80...
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # [Tue May 14 12:29:15 2013 PDT] ACK backlog queue is overflown: 129 > 128
    # 从输出中我们可以看到，有一些ACK backlog队列溢出发生，这意味这对应的SYN数据包被内核丢弃掉了

# 分析指定端口的accept队列的长度分布
./tcp-accept-queue --port=80 --distr
    # WARNING: Tracing SYN & ACK backlog queue length distribution on the listening port 80...
    # Hit Ctrl-C to end.
    # SYN queue length limit: 512
    # Accept queue length limit: 128
    # ^C
    # === SYN Queue ===
    # min/avg/max: 0/2/8
    # value |-------------------------------------------------- count
    #     0 |@@@@@@@@@@@@@@@@@@@@@@@@@@                         106
    #     1 |@@@@@@@@@@@@@@@                                     60
    #     2 |@@@@@@@@@@@@@@@@@@@@@                               84
    #     4 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       176
    #     8 |@@                                                   9
    #    16 |                                                     0
    #    32 |                                                     0
    # 可以看到有106个SYN队列长度为0的采样，有60个SYN队列长度为1的采样，有84个采样的队列长度在[2,4)区间。大部分采样的SYN队列长度在0~8之间
    # === Accept Queue ===
    # min/avg/max: 0/93/129
    # value |-------------------------------------------------- count
    #     0 |@@@@                                                20
    #     1 |@@@                                                 16
    #     2 |                                                     3
    #     4 |@@                                                  11
    #     8 |@@@@                                                23
    #    16 |@@@                                                 16
    #    32 |@@@@@@                                              33
    #    64 |@@@@@@@@@@@@                                        63
    #   128 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 250
    #   256 |                                                     0
    #   512 |                                                     0
    #
```

> **注意事项：** 该工具需要gcc4.5+(最好是gcc4.7+)编译的linux内核支持，因为低于4.5版本的gcc会为C内联函数生成不完整的DWARF调试信息。同时，建议在编译内核时开启DWARF格式第3版本或者更高。(通过在gcc命令行中使用`-gdwarf-3`或者`-gdwarf-4`参数)

#### SystemTap脚本源码

```stap
global count

probe begin {
    warn("Tracing SYN & ACK backlog queue overflows on the listening port 4000...\n")
}

probe kernel.function("tcp_v4_conn_request") {
    tcphdr = __get_skb_tcphdr($skb)
    dport = __tcp_skb_dport(tcphdr)

    if (dport == 4000) {
        syn_qlen = @cast($sk, "struct inet_connection_sock")->icsk_accept_queue->listen_opt->qlen
        max_syn_qlen_log = @cast($sk, "struct inet_connection_sock")->icsk_accept_queue->listen_opt->max_qlen_log
        max_syn_qlen = (2 << max_syn_qlen_log)
        if (syn_qlen > max_syn_qlen) {
            now = tz_ctime(gettimeofday_s())
            printf("[%s] SYN queue is overflown: %d > %d\n", now, syn_qlen, max_syn_qlen)
            count++
        }
        //printf("syn queue: %d <= %d\n", qlen, max_qlen)
        ack_backlog = $sk->sk_ack_backlog
        max_ack_backlog = $sk->sk_max_ack_backlog
        if (ack_backlog > max_ack_backlog) {
            now = tz_ctime(gettimeofday_s())
            printf("[%s] ACK backlog queue is overflown: %d > %d\n", now, ack_backlog, max_ack_backlog)
            count++
        }
        //printf("ACK backlog queue: %d <= %d\n", ack_backlog, max_ack_backlog)
        if (count >= 10) {
            exit()
        }
    }
}
```

### 6.tcp-recv-queue

该工具可以分析TCP receive队列的排队延迟。这里的排队延迟，是指以下两个事件之间延时：

- 上一个在用户空间发起的`recvmsg()`系统调用后，第一个包进入TCP receive队列
- 下一个`recvmsg()`系统调用消费了TCP receive队列的

大量的receive队列延迟，通常意味着用户进程忙于消费涌入的请求，这可能会导致客户端的超时错误。

- TCP receive队列中的零长度数据包(FIN包)将会被工具忽略
- 通过`--dport`参数，来指定接收数据包的目标端口
- 通过`--time`参数，来指定采样周期(单位秒)

```bash
tcp-recv-queue [optoins]
    -a <args>       将额外的参数传递给stap程序
    -d              输出SystemTap脚本源码
    -h              显示帮助信息
    --dport=<port>  指定分析的目标端口
    --time=<seconds>输出事件报告和退出前的等待时间(只在--distr时有意义)
# 分析指定接收数据包端口的延迟
./tcp-recv-queue --dport=12345
    # WARNING: Tracing the TCP receive queues for packets to the port 3306...
    # Hit Ctrl-C to end.
    # ^C
    # === Distribution of First-In-First-Out Latency (us) in TCP Receive Queue ===
    # min/avg/max: 1/2/42
    # value |-------------------------------------------------- count
    #     0 |                                                       0
    #     1 |@@@@@@@@@@@@@@                                     20461
    #     2 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  69795
    #     4 |@@@@                                                6187
    #     8 |@@                                                  3421
    #    16 |                                                     178
    #    32 |                                                       8
    #    64 |                                                       0
    #   128 |                                                       0
    # 我们可以看到大部分延迟都落在[2us, 4us)的区间，最大的时延是42us

# 分析某用户进程监听的12345端口在5秒内的TCP接受队列延迟
$ ./tcp-recv-queue --dport=12345 --time=5
    # WARNING: Tracing the TCP receive queues for packets to the port 1984...
    # Sampling for 5 seconds.
    #
    # === Distribution of First-In-First-Out Latency (us) in TCP Receive Queue ===
    # min/avg/max: 1/1401/12761
    # value |-------------------------------------------------- count
    #     0 |                                                       0
    #     1 |                                                       1
    #     2 |                                                       1
    #     4 |                                                       5
    #     8 |                                                     152
    #    16 |@@                                                  1610
    #    32 |                                                      35
    #    64 |@@@                                                 2485
    #   128 |@@@@@@                                              4056
    #   256 |@@@@@@@@@@@@                                        7853
    #   512 |@@@@@@@@@@@@@@@@@@@@@@@@                           15153
    #  1024 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  31424
    #  2048 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   20454
    #  4096 |@                                                    862
    #  8192 |                                                      19
    # 16384 |                                                       0
    # 32768 |                                                       0
```

> **注意事项：** 该工具需要gcc4.5+(最好是gcc4.7+)编译的linux内核支持，因为低于4.5版本的gcc会为C内联函数生成不完整的DWARF调试信息。同时，建议在编译内核时开启DWARF格式第3版本或者更高。(通过在gcc命令行中使用`-gdwarf-3`或者`-gdwarf-4`参数)

#### SystemTap脚本源码

```stap
global latency_stats
global start_times
global found

probe begin {
    warn("Tracing the TCP receive queues for packets to the port 4000...\nSampling for 5 seconds.\n")
}

/* TODO: take into account the TCP out_of_order queue (i.e., tcp_ofo_queue). */
probe kernel.function("tcp_queue_rcv")!, kernel.function("tcp_data_queue") {
    tcphdr = __get_skb_tcphdr($skb)
    dport = __tcp_skb_dport(tcphdr)
    sport = __tcp_skb_sport(tcphdr)

    if (dport == 4000 && start_times[$sk, sport] == 0) {
        //printf("tcp_queue_rcv: queue=%p sk=%p sport=%d\n",
        //&$sk->sk_receive_queue, $sk, sport)
        if ($skb->len > 0) {
            //println("probe func: ", probefunc())
            if (@cast($skb->cb, "tcp_skb_cb")->seq != @cast($skb->cb, "tcp_skb_cb")->end_seq) {
                start_times[$sk, sport] = gettimeofday_us()
            } else {
                //println("found seq == end_seq")
            }
        }
    }
}

probe kernel.function("tcp_recvmsg"), kernel.function("tcp_recv_skb") {
    q = &$sk->sk_receive_queue
    skb = $sk->sk_receive_queue->next
    if (q != skb) {
        /* queue is not empty */
        tcphdr = __get_skb_tcphdr(skb)
        dport = __tcp_skb_dport(tcphdr)
        if (dport == 4000) {
            sport = __tcp_skb_sport(tcphdr)
            begin = start_times[$sk, sport]
            if (begin > 0) {
                //printf("tcp recvmsg: port=4000 sk=%p\n", $sk)
                latency_stats <<< (gettimeofday_us() - begin)
                found = 1
                delete start_times[$sk, sport]
            }
        }
    }
}

probe kernel.function("tcp_close"), kernel.function("tcp_disconnect") {
    q = &$sk->sk_receive_queue
    skb = $sk->sk_receive_queue->next
    if (q != skb) {
        /* queue is not empty */
        tcphdr = __get_skb_tcphdr(skb)
        dport = __tcp_skb_dport(tcphdr)
        if (dport == 4000) {
            sport = __tcp_skb_sport(tcphdr)
            delete start_times[$sk, sport]
        }
    }
}

probe end {
    if (!found) {
        println("\nNo queued received packets found yet.")
    } else {
        println("\n=== Distribution of First-In-First-Out Latency (us) in TCP Receive Queue ===")
        printf("min/avg/max: %d/%d/%d\n", @min(latency_stats), @avg(latency_stats), @max(latency_stats))
        println(@hist_log(latency_stats))
    }
}

probe timer.s(5) {
    exit()
}
```

### 7.check-debug-info

对于指定的正在运行的进程，该工具可以检测它里面哪些可执行文件没有包含调试信息。用户进程不一定要是nginx，可以是任意用户进程。与进程关联的可执行文件，以及被进程加载的所有.so文件，都将会被检测DWARF信息(linux中的调试符号格式)。

调试符号一般是软件在编译的时候，由编译器生成的供调试使用的元信息。这些元信息可以将编译后的二进制程序中的函数和变量的地址、数据结构的内存分布等信息，映射回源代码里的抽象实体名称(函数名、变量名、类型名等)。

```bash
check-debug-info -p <pid>

# 检查用户进程(pid为12345)的可执行文件和加载的.so文件是否包含debug信息
./check-debug-info -p 12345
    # File /usr/lib64/ld-2.15.so has no debug info embedded.
    # File /usr/lib64/libc-2.15.so has no debug info embedded.
    # File /usr/lib64/libdl-2.15.so has no debug info embedded.
    # File /usr/lib64/libm-2.15.so has no debug info embedded.
    # File /usr/lib64/libpthread-2.15.so has no debug info embedded.
    # File /usr/lib64/libresolv-2.15.so has no debug info embedded.
    # File /usr/lib64/librt-2.15.so has no debug info embedded.
```

### 8.resolve-inlines

该工具调用`addr2line`程序去解决由`sample-*`工具生成的内联函数。PIC(Position-Indenpendent Code，位置无关代码)里面的内联函数现在还不支持

```bash
# 接受两个命令行参数，bt文件和可执行文件
./resolve-inlines a.bt [/path/to/nginx] > new-a.bt
```

### 9.resolve-src-lines

和`resolve-inlines`工具类似，但是将他们的源代码文件名和源代码行数进行了扩展。
