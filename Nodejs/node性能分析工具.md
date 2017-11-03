# 性能分析工具

## 1. node-memwatch / memwatch-next

发现代码存在的内存泄露问题，也可以做在不同时间点堆的比较。

````shell
# 安装memwatch(有4、5年未更新)
$ npm install -g node-memwatch
# 或者安装memwatch-next
$ npm install -g memwatch-next
````

### 堆分配趋势

````javascript
var memwatch = require('memwatch-next');

// 通过Publish/Subscribe模式，监听内存泄漏事件
// 一个简单的侦测算法来提醒你应用程序可能存在内存泄漏。即如果经过连续五次GC，内存仍被持续分配而没有得到释放，node-memwatch就会发出一个leak事件
// {
//     start (开始时间)
//     end (结束时间)
//     growth (内存增长)
//     reason (原因)
// }
memwatch.on('leak', function (info) {
    ...
})
````

### 堆统计

````javascript
var memwatch = require('memwatch-next');

// memwatch能在任何一个JS对象分配之前，紧随着一次完整的垃圾回收(full GC)和内存压缩(heap compaction)，将发出一个stats事件
// 使用了V8的post-gc钩子，V8::AddGCEpilogueCallback，来在每次垃圾回收触发时收集堆使用信息
// {
//     usage_trend (使用趋势)
//     current_base (当前基数)
//     estimated_base (预期基数)
//     num_full_gc (完整的垃圾回收次数)
//     num_inc_gc (增长的垃圾回收次数)
//     heap_compactions (内存压缩次数)
//     min (最小)
//     max (最大)
// }
// 如果num_inc_gc值特别高，说明V8在拼命地尝试清理内存
memwatch.on('stats', function (stats) {
    ...
})
````

### 堆比较

````javascript
// 第一次快照
var hd = new memwatch.HeapDiff();

// 执行一些操作
...

// 第二次快照，然后计算两次的差异
// HeapDiff方法在进行数据采样前会先进行一次完整的垃圾回收，以使得到的数据不会充满太多无用的信息
// memwatch的事件处理会忽略掉由HeapDiff触发的垃圾回收事件，所以在stats事件的监听回调函数中你可以安全地调用HeapDiff方法
var diff = hd.end();
````

## 2. node-headdump

### 安装node-gyp构建工具

````
# 安装python2.7(不支持3.x)

# 安装node-gyp
$ npm install -g node-gyp
# 如果存在多个版本的python，应该指定python路径
$ node-gyp --python [/path/to/python2.7]
# 如果通过npm调用node-gyp并且存在多个版本的python，需要npm的python键值指定为python路径
$ npm config set python [/path/to/executable/python2.7]

# 修改配置
$ npm config set msvs_version 2015
````
