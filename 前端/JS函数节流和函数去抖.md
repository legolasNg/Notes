## 原因

window部分事件频繁被触发，导致频繁执行DOM操作、资源加载等重行为，导致UI停顿甚至浏览器crash:

- window对象的resize、scroll事件
- 拖拽时的mousemove事件
- 射击游戏中的mousedown、keydown事件
- 文字输入、自动完成的keyup事件

对于window的resize事件，优化思路为：在一段时间内，只执行一次resize事件，即setTimemout N毫秒后执行后续处理。其他的一些事件优化，可以一定频率执行后续处理。

## throttle(函数节流)

函数调用的频度调节器，是连续执行时间间隔控制。

```javascript
/**
* 频率控制，返回函数连续调用时，action执行频率限定为 次 / delay
* @param delay {number}
* @param action {function}
* @return {function}
**/
var throttle = function (delay, action) {
    var last = 0;
    return function () {
        var curr = new Date().getTime();    // +new Date()
        if (curr - last > delay) {
            action.apply(this, arguments);
            last = curr;
        }
    }
}
```

### underscore代码实现

```javascript
_.throttle = function (func, wait, options) {
    var context, args, result;
    var timeout = null;
    var previous = 0;
    if (!options) options = {};

    var later = function() {
        previous = options.leading === false ? 0 : _.now();
        timeout = null;
        result = func.apply(context, args);
        if (!timeout) context = args = null;
    };

    return function() {
        var now = _.now();
        if (!previous && options.leading === false) previous = now;
        var remaining = wait - (now - previous);
        context = this;
        args = arguments;
        // 一般来说remaining <= 0就已经足够证明达到wait的时间间隔，这里还考虑到客户端修改系统时间后马上执行func函数
        if (remaining <= 0 || remaining > wait) {
            clearTimeout(timeout);
            timeout = null;
            previous = now;
            result = func.apply(context, args);
            if (!timeout) context = args = null;
        } else if (!timeout && options.trailing !== false) {
            timeout = setTimeout(later, remaining);
        }
        return result;
    };
}
```

## debounce(函数去抖)

函数调用的防反跳，将延迟函数的执行(真正执行)在函数最后一次调用时刻的N毫秒之后。

### underscore代码实现

```javascript
_.debounce = function(func, wait, immediate) {
    var timeout, args, context, timestamp, result;

    var later = function() {
        var last = _.now() - timestamp;

        if (last < wait && last > 0) {
            timeout = setTimeout(later, wait - last);
        } else {
            timeout = null;
            if (!immediate) {
                result = func.apply(context, args);
                if (!timeout) context = args = null;
            }
        }
    };

    return function() {
        context = this;
        args = arguments;
        timestamp = _.now();
        var callNow = immediate && !timeout;
        if (!timeout) timeout = setTimeout(later, wait);
        if (callNow) {
            result = func.apply(context, args);
            context = args = null;
        }

        return result;
    };
};
```
