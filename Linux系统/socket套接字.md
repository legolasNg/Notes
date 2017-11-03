### 网间进程通信

网络中使用一个三元组在全局唯一标识一个进程：(protocol, local_address, local_port);
完整的网间通信需要一个五元祖来标识：(protocol, local_address, local_port, remote_address, remote_port)

### 套接字API

- socket() 创建一个新的确定类型的套接字，类型用一个整型数值标识(文件描述符)，并为它分配系统资源。
- bind() 一般用于服务端，将一个套接字与一个套接字地址结构(比如一个指定的本地端口和IP地址)相关联。
- listen() 用于服务端，使一个绑定的TCP套接字进入监听状态。
- connect() 用于客户端，为一个套接字分配一个自由的本地端口号。(如果是TCP套接字，它会试图获得一个新TCP连接)
- accept() 用于服务端，接受一个从远程客户端发出的创建一个新的TCP连接的接入请求，创建一个新的套接字，与该连接相应的套接字地址相关联。
- send()和recv()，write()和read()，或者recvfrom()和sendto()，用于往/从远程套接字发送和接受数据。
- close() 用于系统释放分配给一个套接字的资源。(如果是TCP，连接会被中断)
- gethostbyname()和gethostbyaddr() 用于解析主机名和地址。
- select()、poll()或者epoll() 用于确定套接字状态。(可写、可读、错误)
- getsocketopt() 用于查询指定套接字一个特定的套接字选项的当前值。
- setsocketopt() 用于为指定套接字设定一个特定的套接字选项。

### `int socket(int domain, int type, int protocol)`

为通讯创建一个端点，为套接字返回一个文件描述符。如果发生错误，函数返回值为-1.

- `domain` 为创建的套接字指定协议集(Protocol Family)或者地址族(Address Family)
    + AF_INET：IPV4网络协议
    + AF_INET6：IPV6网络协议
    + AF_UNIX：本地套接字(一个文件)
- `type` socket类型
    + SOCK_STREAM：可靠的面向流服务或者流套接字(提供了一个面向连接、可靠的数据传输服务，数据无差错、无重复地发送，且按发送顺序接收。内设流量控制，避免数据流超限；数据被看作是字节流，无长度限制)
    + SOCK_DGRAM：数据报文服务或者数据报文套接字(提供了一个无连接服务。数据包以独立包形式被发送，不提供无错保证，数据可能丢失或重复，并且接收顺序混乱)
    + SOCK_SEQPACKET：可靠的连续数据包服务
    + SOCK_RAW：网络层上自行指定运输层协议头，即原始套接字(允许对较低层协议，如IP、ICMP直接访问，常用于检验新的协议实现或访问现有服务中配置的新设备)
- `protocol` 指定实际使用的传输协议(协议在<netinet/in.h>中有详细说明)
    + IPPROTO_TCP：TCP传输协议
    + IPPROTO_SCTP：SCTP传输协议
    + IPPROTO_UDP：UDP传输协议
    + IPPROTO_DCCP：DCCP传输协议

### `int bind(int sockfd, const struct sockaddr *my_addr, socklen_t addrlen)`

为一个套接字分配地址。当socket()创建套接字后，只赋予其所使用的协议，并未分配地址。在接受其他主机的连接前，必须先调用bind()为套接字分配一个地址。发生错误返回-1，成功返回0。

- `sockfd`：使用bind函数的套接字描述符
- `my_addr`：指向sockaddr结构(用于表示所分配地址)的地址
- `addrlen`：用socket_t字段指定了sockaddr结构的长度

### `int listen(int sockfd, int backlog)`

当socket和一个地址绑定以后，listen()函数会开始监听可能的连接请求。这只能在有可靠数据流保证的时候使用，例如SOCK_STREAM, SOCK_SEQPACKET等数据类型。一旦被接受，返回0表示成功，错误返回-1。

- `sockfd`：一个socket的描述符
- `backlog`：一个决定监听队列大小的整数，当有一个连接请求到来，就会进入此监听队列。当一个连接请求被accept()接受，则从监听队列中移出。当队列满了之后，新的连接请求会返回错误。

### `int accept(int sockfd, struct sockaddr *cliaddr, socklen_t *addrlen)`

当应用程序监听来自其他主机的面向数据流的连接时，通过事件(比如select()、poll()、epoll()等系统调用)通知它。必须用accept()函数初始化连接，accept()为每个连接创建新的套接字并从监听队列中移出这个连接。
返回新的套接字描述符，出错返回-1。进一步通讯必须通过该套接字。(DGRAM套接字不要求用accept()处理，因为接收方可能用监听套接字立即处理这个请求)

- `sockfd`：监听的套接字描述符
- `cliaddr`：指向sockaddr结构体的指针，客户端地址信息。
- `addrlen`：指向socklen_t的指针，确定客户端地址结构的长度

### `int connect(int sockfd, const struct sockaddr *serv_addr, socklen_t addrlen)`

connect()系统调用为一个套接字设置连接，参数有文件描述符和主机地址。某些类型的套接字是无连接的，大多数是UDP协议，对于这种套接字，连接时：默认发送和接受数据的主机由给定的地址确定，可以使用send()和recv()。返回-1表示出错，0表示成功。

### `struct hostent *gethostbyname(const char *name)`
### `struct hostent *gethostbyaddr(const void *addr, int len, int type)`

gethostbyname()和gethostbyaddr()函数是用来解析主机名和地址的，可能会使用DNS服务或者主机上的其他解析机制(比如查询/etc/hosts)。返回一个指向struct hostent的指针，这个结构体描述一个IP主机。
出错返回NULL指针，可以通过检查h_errno来确定是临时错误还是未知主机，正确返回一个有效的struct hostent * 。
这两个函数可能过时了，新函数是getaddrinfo()和getnameinfo()，这些新函数是基于addrinfo数据结构。

- `name`：指定主机名
- `addr`：指向struct in_addr的指针，包含主机的地址。
- `len`：给出addr的长度，以字节为单位。
- `type`：指定地址族的类型(例如AF_INET)
