# Nginx说明

## 1、安装

````
$ sudo yum install nginx pcre perl pcre-devel zlib zlib-devel
````

## 2、配置

````
# 运行用户和用户组
user apache apache;

# worker进程数 -- 通常设置为cpu核心数或者2倍核心数，也和硬盘驱动器数量有关系
worker_processes 2;

# cpu亲和力 -- 将进程绑定到一个或者多个处理器或者处理器核心上运行
# 数字位数等于核心数，为1的位置对应worker进程利用的核心
worker_cpu_affinity 01 10；

# 全局的错误日志和日志级别(debug | info | notice | warn | error | crit)
error_log  /data/nginx/error.log warn;

# pid进程文件
pid        /var/run/nginx.pid

# worker进程打开的最多文件描述符数量，理论值应该是最多打开文件数(ulimit -n)
# 会与nginx的worker进程数相除，但是nginx分配请求并不一定均匀
worker_rlimit_nofile 65535

# 工作模式
event {
    # 参考事件模型，use [ kqueue | rtsig | epoll | /dev/poll | select | poll ]
    # epoll是多路复用IO中的一种
    use epoll;

    # 单个worker进程的最大并发数，默认是1024，和物理内存有关
    worker_connections  1024;

    # http 1.1协议下，由于浏览器默认使用两个并发连接
    # 作为http服务器时：max_clients=worker_processes * worker_connections / 2
    # 作为反向代理服务器时: max_clients = worker_processes * worker_connections / 4 (nginx需要同时维持客户端和后端的连接)
    # 并发受IO约束，max_clients要小于系统可以打开的最大文件数。系统可以打开的最大文件数和内存大小成正比 cat /proc/sys/fs/file-max
}

http {
    # 设置mime类型
    include       /etc/nginx/mime.types
    # 默认文件类型 -- 八进制数据流
    default_type  application/octet-stream
    # 默认编码
    charset utf-8;

    # 服务器名字的hash表大小
    server_names_hash_bucket_size 128
    # 请求头的大小限制
    client_header_buffer_size
    # 超过client_header_buffer_size的请求，设置缓存 -- 默认是一个内存分页的大小值
    large_client_header_buffers 4 16k;
    # 请求body的大小限制
    client_max_body_size 8m;
    # 请求body使用的缓冲区大小 -- 默认是两个内存分页的大小值
    client_body_buffer_size 128k;

    # 开启高效文件传输，sendfile指令指定nginx是否调用sendfile函数来输出文件
    # 平衡磁盘和网络I/O处理速度，降低系统负载，默认开启
    # 如果图片显示不正常或者进行下载等应用磁盘I/O重负载应用
    sendfile on;
    # 开启目录列表访问，适合下载服务器，默认关闭
    autoindex off;

    # 防止网络阻塞 -- Nagle和DelayedAcknowledgment的延迟问题
    # 使用长连接时开启，解决小包阻塞。短链接并不需要
    tcp_nodelay on;
    # 影响TCP_NOPUSH(unix)和TCP_CORK(linux),被阻塞数据长度超过MSS时才发送数据包
    tcp_nopush on;

    # 分配keep-alive链接超时时间
    keepalive_timeout 10;
    # 请求头的超时时间
    client_header_timeout 10;
    # 请求body的超时时间
    client_body_timeout 10;
    # 关闭响应超时的客户端连接，释放对应内存空间
    reset_timeout_connection on;
    # 指定客户端的响应超时时间
    send_timeout 10;

    # 开启gzip压缩
    gzip [on | disable];
    # 最小压缩文件大小
    gzip_min_length  1k;
    # 压缩缓冲区大小
    gzip_buffers 4 16k;
    # 压缩版本，默认1.1。对于特殊需求时开启
    gzip_http_version 1.0;
    # 压缩等级，默认为1。压缩级别 1-9，级别越高压缩率越大，压缩时间也越长
    gzip_comp_level 2;
    # 压缩类型。默认包含text/plain
    gzip_types text/plain application/x-javascript text/css application/xml;
    # 请求头中加vary，识别客户端是否需要压缩，避免不支持压缩的浪费时间
    gzip_vary on;
    # 静态资源的预压缩
    gzip_static on;
    # 反向代理时启用
    gzip_proxied [off|expired|no-cache|no-store|private|no_last_modified|no_etag|auth|any]

    # 开启IP并发限制连接数， limit_zone + 名字 + 限制的地址 + 会话存储的空间
    limit_zone name [$binary_remote_addr | $remote_addr] 10m;
    # 通过"令牌桶原理"来限制用户的连接频率
    lit_req_zone $binary_remote_addr zone=name:10m rate=1r/s;

    # 打开文件开启缓存，max指定缓存数量，inactive缓存失效删除时间
    open_file_cache max=100000 inactive=20s;
    # 检查缓存的时间间隔
    open_file_cache_valid 30s;
    # inactive时间内缓存文件的最少使用次数，超过这个数字，文件的更改信息一直在缓存中打开
    open_file_cache_min_uses 2;
    # 无法正确读取时报错
    open_file_cache_errors on;

    # 设置日志格式
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    # access日志文件的路径和格式
    access.log  logs/access.log  main;

    # 指定FastCGI缓存的路径、目录结构等级、关键字区域存储时间、非活动删除时间
    fastcgi_cache_path /usr/local/nginx/fastcgi_cache levels=1:2 keys_zone=TEST:10m inactive=5m;
    # 连接到后端FastCGI的超时时间
    fastcgi_connect_timeout 300;  
    # 向FastCGI传送请求的超时时间 -- 两次握手后的超时时间
    fastcgi_send_timeout 300;
    # 接收FastCGI应答的超时时间 -- 两次握手后的超时时间
    fastcgi_read_timeout 300;  
    # 读取FastCGI应答第一部分(应答头)需要用多大的缓冲区
    fastcgi_buffer_size 64k;  
    # 需要用多少和多大的缓冲区来缓冲FastCGI的应答请求
    fastcgi_buffers 4 64k;
    # 默认是fastcgi_buffer_size的两倍
    fastcgi_busy_buffers_size 128k;  
    # 写入缓存文件时使用多大的数据块，默认是fastcgi_buffer_size的两倍
    #fastcgi_temp_file_write_size 128k;
    # 开启FastCGI缓存并为其指定一个名称
    fastcgi_cache name;
    # 将FastCGI缓存多久
    fastcgi_cache_valid 200 302 1h;
    fastcgi_cache_valid 301 1d;
    fastcgi_cache_valid any 1m;

    # 导入其他配置文件
    include /etc/nginx/conf.d/*.conf
}
````

## 3、启动

````
## sysvinit或者UpStart
$ sudo chkconfig nginx on
$ sudo service nginx start
## systemd
$ sudo systemctl enable nginx.service
$ sudo systemctl start nginx.service
````

## 4、解决方案

### Nginx fastcgi转发

````
server {
    listen       7000;
    server_name  localhost;

    location / {
        # 服务器的默认网站根目录位置
        root /website/;
        # 首页索引文件的名称
        index index.php index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root  ./html;
    }
    location ~ \.php$ {
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /website$fastcgi_script_name;
        include        fastcgi_params;
    }
}
````

### Nginx 端口转发/反向代理

````
server {
    # 虚拟主机监听的端口
    listen       80;
    # 自定义域名访问
    server_name  www.**.com **.com;

    access_log  /var/log/nginx/official.access.log  main;

    location / {
        proxy_redirect          off;
        # 转发路径
        proxy_pass              http://127.0.0.1:8080/;
        # 设置主机头和客户端真实地址，以便服务器获取客户端真实IP
        proxy_set_header        X-Real-IP               $remote_addr;
        proxy_set_header        X-Forwarded-For         $proxy_add_x_forwarded_for;
        # 反向代理配置
        proxy_set_header        Host                    $host;

        #允许客户端请求的最大单文件字节数  
        client_max_body_size 10m;   
        #缓冲区代理缓冲用户端请求的最大字节数  
        client_body_buffer_size 128k;    
        #nginx跟后端服务器连接超时时间(代理连接超时)  
        proxy_connect_timeout 90;   
        #后端服务器数据回传时间(代理发送超时)  
        proxy_send_timeout 90;   
        #连接成功后，后端服务器响应时间(代理接收超时)  
        proxy_read_timeout 90;   
        #设置代理服务器（nginx）保存用户头信息的缓冲区大小  
        proxy_buffer_size 4k;   
        #proxy_buffers缓冲区，网页平均在32k以下的设置  
        proxy_buffers 4 32k;   
        #高负荷下缓冲大小（proxy_buffers*2）  
        proxy_busy_buffers_size 64k;   
        #设定缓存文件夹大小，大于这个值，将从upstream服务器传  
        #proxy_temp_file_write_size 64k;  
        #proxy_cache cache_one;
        #proxy_cache_valid 200 302 1h;
        #proxy_cache_valid 301 1d;
        #proxy_cache_valid any 5m;
        #expires 10d;
    }
    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
````

### Nginx 负载均衡

````
upstream backend {
    # upstream的负载均衡，weight是权重，权值越高被分配到的几率越大
    server 192.168.2.1:8000 weight=3;
    # 每个请求按照ip的hash结果分配，每个访客可以固定一个后端，可以解决session问题
    ip_hash;   
    server 192.168.2.2:8000;
    server 192.168.2.3:8000;
}

server {
    listen      80;
    server_name www.***.com;

    location / {
        proxy_pass  localhost://backend;
    }
}
````

### Nginx 重定向

````
rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
if (!-e $request_filename) {
       return 404;
}
````

### Nginx 静态资源

````
location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
        root              /website/;
        access_log        off;
        expires           max;
}
````

### 获取真实IP
经过多层代理后，http后中记录为X-Forwarded-For :  用户IP, 代理服务器1-IP, 代理服务器2-IP, 代理服务器3-IP,

````
map $http_x_forwarded_for  $clientRealIp {
    ## 没有通过代理，直接用 remote_addr
	""	$remote_addr;  
    ## 用正则匹配，从 x_forwarded_for 中取得用户的原始IP
    ## 例如   X-Forwarded-For: 202.123.123.11, 208.22.22.234, 192.168.2.100,...
    ## 这里第一个 202.123.123.11 是用户的真实 IP，后面其它都是经过的 CDN 服务器
	~^(?P&lt;firstAddr&gt;[0-9\.]+),?.*$	$firstAddr;
}

## 通过 map 指令，我们为 nginx 创建了一个变量 $clientRealIp ，这个就是 原始用户的真实 IP 地址，
## 不论用户是直接访问，还是通过一串 CDN 之后的访问，我们都能取得正确的原始IP地址
````

### 测试获取客户端地址

````
server {
	listen   80;
        server_name  www.bzfshop.net;

        ## 当访问 /nginx-test 的时候，输出 $clientRealIp 变量
        ## 浏览器访问时会弹出下载文件
        location /nginx-test {
                echo $clientRealIp;
        }
}
````

### 限制客户端并发请求

每个地址并发连接数为1

````
http {
    limit_zone one  $binary_remote_addr  10m;

    server {
        limit_conn one 1;
    }
}
````

rate=1r/s，每个地址每秒只能通过一次请求；
burst=120，根据漏桶(leaky bucket)原理，请求超过rate定义的速率时，需要延时处理的请求数为120(排队)，超过120请求就会返回503。
nodelay，不延迟请求，要么被处理，要么返回503。此时允许瞬时并发为(burst + rate*time -1)

````
http {
    limit_req_zone  $binary_remote_addr  zone=req_one:10m rate=1r/s;

    server {
        limit_req   zone=req_one  burst=120;
        #limit_req   zone=req_one  burst=120 nodelay;
    }
}
````

### Nginx 记录post请求数据

nginx除了在proxy_pass或fastcgi_pass的Location中读取request_body外，其他地方都不会读取post数据。

借助ngx_lua模块，在输出log前读取request_body

````
location /test {
    lua_need_request_body on;                                                                                            
    content_by_lua 'local s = ngx.var.request_body';
    ...
}

````

访问NginX内置变量ngx.var.request_body(由于 NginX 默认在处理请求前不自动读取request body，所以目前必须显式借助form-input-nginx模块才能从该变量得到请求体，否则该变量内容始终为空)

### HTTP/2 协议

````
server {  
        server_name domain.com www.domain.com;
        listen 443 ssl http2 default_server;
        root /var/www/html;
        index index.html;
        location / {
                try_files $uri $uri/ =404;
        }
        ssl_certificate /etc/nginx/ssl/domain.com.crt;
        ssl_certificate_key /etc/nginx/ssl/domain.com.key;
}
server {
       listen         80;
       server_name    domain.com www.domain.com;
       return         301 https://$server_name$request_uri;
}
````

### IPV6支持

在命令行输入`nginx -V`，看输出中是否有`--with-ipv6`来检测nginx是否支持IPV6，或者编译nginx的时候，在`./configure`后加上`--with-ipv6`编译选项。

nginx配置开启tcp6端口监听

````
# 同时监听tcp端口和tcp6端口，但是会默认连接tcp6端口，可能会造成ipv4网络连接失败
listen  [::]:80;

# 同时监听tcp端口和tcp6端口，只在ipv6环境才会连接tcp6端口
listen  80;
listen  [::]:80 default ipv6only=on;
````
