## [FlameGraph](https://github.com/brendangregg/FlameGraph)

火焰图，是将采样跟踪得到的堆栈信息可视化展示的工具，能快速准确反映代码路径上的频率分布。

### 1.捕获堆栈

堆栈样本可以通过一些profiler(例如Linux perf_event, FreeBSD pmcstat/hwpmc, DTrace, SystemTap)来捕获堆栈样本，然后通过stackcollapse转换。

```bash
# 使用Linux perf_events(也叫做perf)以99赫兹的频率来捕获60秒的堆栈样本
perf record -F 99 -a -g -- sleep 60
perf script > out.perf
# 使用Linux perf_events(也叫做perf)以99赫兹的频率来捕获指定PID的60秒堆栈样本
perf record -F 99 -p [PID] -g -- sleep 60
perf script > out.perf

# 使用DTrace以997赫兹的频率来捕获60秒内核堆栈
dtrace -x stackframes=100 -n 'profile-997 /arg0/ { @[stack()] = count();} tick-60s { exit(0); }' -o out.kernel_stacks
# 使用DTrace以97赫兹的频率来捕获指定PID的60秒用户堆栈
dtrace -x ustackframes=100 -n 'profile-97 /pid == 12345 && arg1/ { @[ustack()] = count(); } tick-60s { exit(0); }' -o out.user_stacks
# 以97赫兹的频率来捕获60秒内(包括在内核中消耗的时间)指定PID的用户堆栈
dtrace -x ustackframes=100 -n 'profile-97 /pid == 12345/ { @[ustack()] == count(); } tick-60s { exit(0); }' -o out.user_stacks

# 如果应用有ustack助手来include被翻译栈帧(nodejs框架)，将ustack()切换为jstack()。使用jstack()来翻译栈帧时需要注意的是，用户堆栈收集速率明显会比内核堆栈慢。
dtrace -n 'profile-997 /execname == "node" && arg1/ { @[jstack(40, 2000)] == count(); } tick-60s { exit(0); }' -o out.stacks
```

### 2.折叠堆栈样本

使用stackcollapse程序将堆栈样本折叠成单行(分组折叠)：

- `stackcollapse.pl`：用于DTrace堆栈
- `stackcollapse-perf.pl`：用于linux perf脚本的perf_event输出
- `stackcollapse-pmc.pl`：用于FreeBSD的`pmcstat -G`输出堆栈
- `stackcollapse-stap.pl`：用于SystemTap堆栈
- `stackcollapse-instruments.pl`：用于XCode Instruments堆栈
- `stackcollapse-vtune.pl`：用于Intel VTune的profile
- `stackcollapse-ljp.awk`：用于Lightweight Java Profiler
- `stackcollapse-jstack.pl`：用于java的jstack输出
- `stackcollapse-gdb.pl`：用于gdb堆栈
- `stackcollapse-go.pl`：用于golang的pprof堆栈

```bash
# 将perf探测的perf_event折叠
./stackcollapse-perf.pl out.perf > out.folded
# 将DTrace堆栈数据折叠
./stackcollapse.pl out.kern_stacks > out.kern_folded
# 将stap探测的堆栈数据折叠
./stackcollapse-stap.pl [filename.out] > [filename.cbt]
```

### 3.生成火焰图

使用flamegraph将堆栈数据渲染成火焰图SVG图片，还可以根据需要将感兴趣的堆栈数据过滤出来单独渲染成火焰图：

```bash
# 生成火焰图
./flamegraph.pl --title="Flame Graph" [filename.cbt] > [filename.svg]
# 过滤部分数据，生成火焰图
grep [filter] [filename.cbt] | ./flamegraph.pl > [filter.svg]
```

#### 用法

```bash
./flamegraph.pl [options] infile > outfile.svg
    --title     ## 修改标题
    --width     ## 图片宽度(默认1200)
    --height    ## 每个栈帧的高度(默认16)
    --minwidth  ## 忽略过小的函数(默认0.1 pixels)
    --fonttype  ## 字体(默认Verdana)
    --fontsize  ## 字体大小(默认12)
    --countname ## 计数标签的后缀(默认"samples")
    --nametype  ## 名字标签的前缀(默认"Function:")
    --colors    ## 设置调色板，可选颜色：hot(默认), mem, io, wakeup, chain, jave, js, perl, red, green, blue, aqua, yellow, purple, orange
    --hash      ## 按照函数名hash后对应颜色
    --cp        ## 使用一致的调色板(pattle.map文件)
    --reverse   ## 生成一个颠倒的堆栈火焰图
    --inverted  ## 冰柱图
    --negate    ## 开启差分色调(blue <-> red)
    --help      ## 帮助
```

#### 统一调色板

如果使用`--cp`选项，程序会使用$colors选择器，并随机生成调色板。后面所有带`--cp`选项生成的所有火焰图都将使用相同的调色谱。后面的火焰图中的新符号将会通过$colors选择器随机生成对应的颜色。

如果不喜欢调色板，只需删除`palette.map`文件即可。

你可以在不同的火焰图间，选用不同的颜色搭配，使得差异更加明显。

现在有2份堆栈捕获，一份是损坏的，一份是正常的：

```bash
# 将会生成一个palette.map文件，每个颜色都是随机生成的。
cat working.folded | ./flamegraph.pl --cp > working.svg
# 这个broken.svg将会使用相同的palette.map文件，相同的事件使用相同的颜色，新事件采用新的颜色搭配。
cat broken.folded | ./flamegraph.pl --cp --colors mem > broken.svg
```

### 4.分析

火焰图中，y轴表示栈的深度，x轴表示样本的总数，栈帧的宽度表示了profile文件中该函数出现的比例，最顶层表示正在运行的函数，再往下就是调用它的栈。
