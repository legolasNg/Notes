# Redis说明

## 1、安装

````
$ sudo yum install redis php-pecl-redis
````

## 2、启动

````
$ sudo systemctl enable redis.service
$ sudo systemctl start redis.service
````

## 3、配置

修改/etc/redis.conf文件

````
# 绑定ip地址
bind 127.0.0.1
# 指定不同的 pid 文件和端口
pidfile /var/run/redis.pid
# 指定监听端口
port 6379

# log日志等级
loglevel warning
# 配置log文件地址
logfile stdout

# 设置数据库个数
databases 16

# 在进行镜像备份时,是否进行压缩
rdbcompression yes
# 镜像备份文件的文件名
dbfilename dump.rdb
# Redis进行数据库镜像备份的频率
save 900 1      #900秒之内有1个keys发生变化时
save 300 10     #300秒之内有10个keys发生变化时
save 60 10000   #60秒之内有10000个keys发生变化时

# 设置该数据库为其他数据库的从数据库
slaveof <masterip> <masterport>
# 指定与主数据库连接时需要的密码验证
masterauth <master-password>
````

## 4."缓存穿透"优化

**缓存穿透**，指查询一个根本不存在的数据，缓存层和存储层都不会命中，但是出于容错的考虑，如果从存储层查不到数据则不写入缓存层。

缓存穿透将导致不存在的数据每次请求都要到存储层去查询，失去了缓存保护后端存储的意义。缓存穿透问题可能会使后端存储负载加大，由于很多后端存储不具备高并发性，甚至可能造成后端存储宕掉。

### 解决方案一：缓存空对象

当第二步存储层未命中时，仍然将空对象保留到缓存层，之后访问这个数据将会从缓存中获取，保护了后端数据源。

缓存空对象会有两个问题：

- 空值做缓存，意味着缓存层存储更多的key，需要更多的空间。比较有效的方法是，将此类数据设置一个较短的过期时间，让其自动剔除。
- 缓存层和存储层会有一段时间窗口的不一致，可能会对业务有一定影响。例如，过期时间设置为5分钟，如果此时存储层添加了这个数据，那么此段时间就会出现缓存层和存储层数据不一致，此时可以使用消息系统或者其他方式清除掉缓存层中的空对象。

缓存空对象伪代码：

```javascript
function get (key) {
    // 从缓存层获取数据
    var cacheValue = cache.get(key);
    // 缓存为空
    if (cacheValue === null || cacheValue === undefined) {
        // 从存储层获取
        var storageValue = storage.get(key);
        cache.set(key, storageValue);
        // 数据为空，设置一个过期时间
        if (storageValue === null || cacheValue === undefined) {
            cache.expire(key, 60*5);
        }
        return storageValue;
    } else {
        // 缓存非空
        return cacheValue;
    }
}
```

### 解决方案二：布隆过滤器(bloom filter)

**布隆过滤器**，1970年由布隆提出，实际上是一个很长的二进制向量和一系列随机映射函数。布隆过滤器可以用于检索一个元素是否在一个集合中，它的优点是空间效率和查询时间都远远超过一般的算法，缺点是有一定的误识别率和删除困难。哈希表也能检索一个元素是否在集合中，但是布隆过滤器只需要哈希表1/8到1/4的大小就能解决同样的问题。

初始状态下，bloom filter是一个m位的位数组，且数据被0填充。同时，我们需要定义k个不同的hash函数，每一个hash函数都随机的将每一个输入元素隐射到位数组中的一个位上。对于一个确定的输入，我们会得到k个索引。

插入元素：经过k个hash函数的映射，我们会得到k个索引，然后将数组中这k个位置全部置为1(不管其中的位是0或者1)。

查询元素：输入元素经过k个hash函数的映射会得到k个索引，如果数组中这k个索引任意一处是0，那么说明这个元素不在集合中；如果该元素处于集合中，那么当插入元素的时候这k个位都是1。布隆过滤器，不会出现false negative(假阴性，漏报)，可能会出现false positive(假阳性，误报)，误报概率在万分之一以下。

在访问缓存层和存储层之前，将存在的key用布隆过滤器提前保存起来，做第一层拦截。这种方法适用于数据命中不高，数据相对固定、实时性低的应用场景(通常是数据集较大)，代码维护较为复杂，但是缓存空间占用小。

可以利用Redis的Bitmaps实现布隆过滤器，github有实现[redis-lua-scaling-bloom-filter](https://github.com/erikdubbelboer/Redis-Lua-scaling-bloom-filter)。

## 5."缓存雪崩"(stampeding herd,奔逃的野牛)优化

**缓存雪崩**，由于缓存层承载着大量请求，有效的保护了存储层，但是如果缓存层由于某些原因整体不能提供服务，于是所有的请求都会达到存储层，存储层的调用量会暴增，造成存储层也会挂掉的情况。

### 解决方案一：保证缓存层服务高可用性

缓存层设计成高可用，即使个别节点、个别机器，甚至机房宕机，依然能提供服务。利用redis cluster或者redis sentinel来实现高可用。

### 解决方案二：依赖隔离组件为后端限流并降级

缓存层和存储层都有出错的概览，将其都视为资源。假如有一个资源不可用，会造成线程全部hang在这个资源上，造成整个系统不可用。降级在高并发系统中非常正常：当某个服务不可用，可以降级补充别的服务。

### 解决方案三：提前演练，设定预案

## 6."缓存热点key"优化

缓存 + 过期时间的策略，可以加速数据读写，又保证数据的定期更新。但是如果以下两个问题同时出现，可能会造成致命危害：

- 当前key是热点key，并发量非常大
- 重建缓存不能在短时间完成，可能是一个复杂计算或者io等。

缓存失效的瞬间，有大量的线程来重建缓存，造成后端负载加大，可能会让应用崩溃。解决方案不能太复杂，给系统带来更多的麻烦，需要遵循以下要求：

- 减少重建缓存的次数
- 数据尽可能一致
- 较少的潜在危险

### 解决方案一：互斥锁(mutex key)

只允许一个线程重建缓存，其他线程等待重建缓存的线程执行完，重新从缓存获取数据即可。可以使用redis的`setnx`命令实现上述功能。

```javascript
function get (key) {
    var value = redis.get(key);
    if (cacheValue === null || cacheValue === undefined) {
        var mutexKey = "mutex:key:" + key;
        // 只允许一个线程重构缓存，使用NX，并使用过期时间EX
        // SET key value [EX seconds] [PX milliseconds] [NX|XX]
        // EX 设置键的过期时间为秒，PX 设置键的过期时间为毫秒。NX 只在键不存在的时候，才对键进行设置操作，XX 只在键存在的时候，才对键进行设置操作。
        if (redis.set(mutexKey, "1", "ex 180", "nx")) {
            // 从数据源获取数据
            value = db.get(key);
            // 回写redis，并且设置过期时间
            redis.setex(key, timeout, value);
            // 删除互斥锁
            redis.delete(mutexKey);
        } else {
            // 其他线程休息1000毫秒后重试
            setTimeout(function () {
                get(key);
            }, 1000);
        }
    }
    return value;
}
```

### 解决方案二：永不过期

**永不过期**，包含两层意思：

- 缓存层层面，确实没有设置过期时间，所以不会出现热点key过期后产生的问题，也就是物理不过期。
- 功能层层面，为每个value设置一个逻辑过期时间，当发现超过逻辑过期时间后，会使用单独的线程去构建缓存。

永不过期，有效杜绝了热点key产生的问题，但是会出现数据不一致的情况。

```javascript
function get (key) {
    var cacheValue = redis.get(key);
    var value = cacheValue.value, logicTimeout = cacheValue.logicTimeout;
    // 如果逻辑时间小于当前时间，开始后台构建
    if (logicTimeout <= new Date().getTime()/1000) {
        var mutexKey = "mutex:key:" + key;
        if (redis.set(mutexKey, "1", "ex 180", "nx")) {
            var dbValue =  db.get(key), newLogicTimeout = new Date().getTime()/1000 + 60*60;
            redis.set(key, (dbValue, newLogicTimeout));
            redis.delete(mutexKey);
        }
    }

    return value;
}
```

并发量较大的应用，使用缓存时有三个目标：

1. 加快用户访问速度，提高用户体验。
2. 降低后端负载，减少潜在风险，保证系统平稳。
3. 保证数据"尽可能"即使更新。

互斥锁：方案较为简单，但是存在一定隐患，如果构建缓存过程出现问题或者时间较长，可能会存在死锁和线程池阻塞的风险，但是该方法能较好降低后端负载并且数据一致性比较好。
永不过期：由于没有设置真正的过期时间，实际上已经不存在热点key等一系列问题，但是会出现数据不一致的情况，同时代码复杂度会增大。
