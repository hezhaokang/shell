#!/bin/bash 


. /etc/os-release




# 颜色展示

color() {
    RES_COL=60
    MOVE_TO_COL="echo -en \e[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \e[1;32m"
    SETCOLOR_FAILURE="echo -en \e[1;31m"
    SETCOLOR_WARNING="echo -en \e[1;33m"
    SETCOLOR_END="echo -en \e[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "0" ]; then
        ${SETCOLOR_SUCCESS}
        echo -n $" OK "
    elif [ $2 = "1" ]; then
        ${SETCOLOR_FAILURE}
        echo -n $" FAILURE "
    else
        ${SETCOLOR_WARNING}
        echo -n $" WARNING "
    fi
    ${SETCOLOR_END}
    echo -n "]"
    echo
}

# 下载wget
install_wget () {
    if [ $ID = "centos" -o $ID = "rocky" ]; then
        if ! which wget > /dev/null ;then
            yum install -y wget
        fi
    else
        if ! which wget > /dev/null ;then
            apt install -y wget
        fi
    fi
}


# 下载java
install_java () {
    if [ $ID = "centos" -o $ID = "rocky" ]; then
        wget https://www.mysticalrecluse.com/script/tools/jdk-11.0.23_linux-x64_bin.rpm
        rpm -ivh jdk-11.0.23_linux-x64_bin.rpm
    else
        wget https://www.mysticalrecluse.com/script/tools/jdk-11.0.23_linux-x64_bin.deb
        dpkg -i jdk-11.0.23_linux-x64_bin.deb
    fi

    if [ $? -eq 0 ]; then 
        color "JAVA准备成功，继续安装Tomcat!" 0
    else
        color "Java安装失败，退出" 1
        exit
    fi
}

# 下载tomcat
install_tomcat () {
    
    wget https://www.mysticalrecluse.com/script/tools/apache-tomcat-9.0.89.tar.gz
    tar xf apache-tomcat-9.0.89.tar.gz -C /usr/local/
    ln -sv /usr/local/apache-tomcat-9.0.89/ /usr/local/tomcat
    ln -sv /usr/local/tomcat/bin/* /usr/local/bin/
    useradd -r -s /sbin/nologin tomcat
    chown -R tomcat.tomcat /usr/local/tomcat/
    cat > /lib/systemd/system/tomcat.service << EOF
[Unit]
Description=Tomcat
After=syslog.target.network.target

[Service]
Type=forking
Environment=Java_HOME=/usr/lib/jvm/jdk-11-oracle-x64/
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh
PrivateTmp=true
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
}

install_wget
install_java
install_tomcat
