## 定义

服务端与客户端全双工(full-duplex)通信，可以传输基于消息的文本和二进制数据。是浏览器中最靠近套接字的API，除了最初建立连接时需要借助于现有的HTTP协议，其他时候直接基于TCP完成通信。

协议定义为ws和wss协议，分别为普通请求和基于SSL的安全传输，占用端口和HTTP协议一样，ws为80端口，wss为443端口，支持HTTP代理。

## URI

- ws-URI: `ws://[host]:[port]/[path]?[query]`
- wss-URI: `wss://[host]:[port]/[path]?[query]`

## WebSocket 握手

当建立一个Websocket连接时，为了保持基于HTTP协议的服务器软件和中间件进行兼容工作，客户端打开一个连接时使用与HTTP连接的同一端口连接到服务器，被设计为一个升级的HTTP请求。

### 1.客户端握手请求

此时连接状态是CONNECTING，客户端提供一个websocket URI(host、port、resource-name、是否安全连接标记)。

```
GET /chat HTTP/1.1                                    // 请求方法必须为GET，HTTP版本最低为1.1
    Host: server.example.com
    Connection: Upgrade                         // 告知服务器当前请求是升级的
    Upgrade: websocket                          // 告诉服务器该HTTP请求是升级的Websocket连接
    Origin： http://example.com                 // 告知服务器，客户端所属域
    Sec-WebSocket-Key: 9u+F2xlFQzCpRlcXzJWGBg== // 客户端发送key给服务端进行校验，然后服务端返回一个校验过后的字符串给客户端，校验通过之后才能建立socket连接。
    Sec-WebSocket-Version: 13                   // 请求的WebSockets的版本
    Sec-WebSocket-Protocol: soap, wamp          // WebSockets子协议(服务端需从客户端所建议并且支持的协议中挑选一个)
```

如果客户端已经有一个Websocket连接到远程服务端，不论是否是同一个服务器，客户端必须等待上一个连接关闭之后才能发送新的连接请求，也就是说同一个客户端一次只能存在一个WebSockets连接。如果想同一个服务器有多个连接，客户端必须要串行化进行。
如果服务器向处理多个websocket应用，只需要定义多个route即可。客户端通过不同的请求地址，来访问不同的应用。

### 2.服务器握手响应

```
HTTP/1.1 101 Switching Protocols                        // 返回HTTP协议版本和状态码(101 Switching Protocols是变换协议，状态码如果不为101将不会建立连接)
    Connection: Upgrade                                 // 服务端同意使用升级
    Upgrade: websocket                                  // 同意使用Websocket连接
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=  // 服务端将加密处理后的握手key通过这个字段返回给客户端。key + GUID(全局唯一标识符)，拼接后SHA-1哈希，在进行base64编码
    Sec-WebSocket-Protocol: chat                        // 指明WebSockets子协议
```

### 3.持续追踪客户端

这部分和Websocket协议没有直接的关系，但是务必注意：服务器必须持续追踪每个客户端的socket以避免进行重复的握手。(同一个客户IP地址可能会尝试连接多次)

## 收发数据帧

客户端和服务端都能在任意时候发送数据，所有帧都是用一种格式，从客户端发送到服务端的数据是被XOR异或加密(使用一个32位的key)掩蔽的。

所有数据传输都是UTF8编码的数据，当一段接收到的字节流数据不是一个有效的UTF8数据流，接收方必须马上关闭连接。这个规则在开始握手一直到数据交换过程都要进行验证。

## WebSocket的心跳包

在握手后的任何一个时间点，客户端或者服务端可以选择发送一个ping包给对方，当ping包被收到时，接受者必须尽可能快地发挥pong包。(可以使用这个机制确认客户端仍然处于连接状态)

一个ping包或者pong包就是一个常规的数据帧，但是它是控制帧。ping包的操作码为0x9，pong包的操作码为0xA，最大的有效负载长度为125。

- 当你收到一个ping包时，发回一个和ping包载荷数据完全相同的pong包。
- 当你在从未发送过ping包的情况下收到pong包，请忽略它。
- 当你在发回pong包之前，如果接收到多个ping包，只要发送一个pong包即可。

## 关闭连接

要关闭一个连接，客户端或者服务端可以发送一个带有一段特殊控制序列数据的控制帧，来开始挥手过程。一旦接收到这样的帧，另一方发送关闭帧作为回应。任何关闭连接之后的数据都将被丢弃。
