#!/bin/bash
# 代理服务器地址
PROXY="http://10.0.0.1:10810"

# 代理设置函数
start_proxy() {
    export http_proxy=$PROXY
    export https_proxy=$PROXY
    export ftp_proxy=$PROXY
    export no_proxy="localhost,127.0.0.1,::1"

    # 持久化到 ~/.bashrc
    echo "export http_proxy=$PROXY" >> ~/.bashrc
    echo "export https_proxy=$PROXY" >> ~/.bashrc
    echo "export ftp_proxy=$PROXY" >> ~/.bashrc
    echo 'export no_proxy="localhost,127.0.0.1,::1"' >> ~/.bashrc

    echo "代理已开启，当前代理地址：$PROXY"
}

# 代理关闭函数
stop_proxy() {
    unset http_proxy https_proxy ftp_proxy no_proxy

    # 从 ~/.bashrc 中删除代理配置
    sed -i '/export http_proxy=/d' ~/.bashrc
    sed -i '/export https_proxy=/d' ~/.bashrc
    sed -i '/export ftp_proxy=/d' ~/.bashrc
    sed -i '/export no_proxy=/d' ~/.bashrc

    echo "代理已关闭"
}

# 判断用户输入的选项
case "$1" in
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    *)
        echo "用法: $0 {start|stop}"
        exit 1
        ;;
esac

