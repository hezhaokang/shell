#!/bin/bash

MYSQL_PORT=3308
MYSQL_VERSION=8.2.0
#MYSQL_VERSION=9.0.1
#MYSQL_VERSION=8.4.2
#MYSQL_VERSION=8.4.0
#MYSQL_VERSION=8.3.0
#MYSQL_VERSION=8.2.0
#MYSQL_VERSION=8.1.0
#MYSQL_VERSION=5.7.44
#MYSQL_VERSION=5.6.51
#MYSQL_VERSION=5.5.62
MYSQL_MID_VERSION=MySQL-`echo $MYSQL_VERSION | awk -F'.' '{print $1"."$2}'`/
MYSQL_FILE=mysql-${MYSQL_VERSION}-linux-glibc2.17-x86_64.tar.xz
MYSQL_URL=https://dev.mysql.com/get/Downloads/
SRC_DIR=/usr/local/src
MYSQL_INSTALL_DIR=/data/mysql$MYSQL_PORT

. /etc/os-release


color() {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ]; then
	    ${SETCOLOR_SUCCESS}
	    echo -n $" OK "

    elif [ $2 = "failure" -o $2 = "1" ]; then
	    ${SETCOLOR_FAILURE}
	    echo -n $" FAILED "
    else 
	    ${SETCOLOR_WARNING}
	    echo -n $" WARNING "
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo
}

check() {
	[ -e ${MYSQL_INSTALL_DIR} ] && { color "nginx 已安装，请卸载后再安装" 1; exit;}
	cd ${SRC_DIR}
	if [ -e ${MYSQL_FILE} ]; then
		color "相关文件已准备好" 0
	else
		color "开始下载源码包" 0
		wget $MYSQL_URL$MYSQL_MID_VERSION$MYSQL_FILE
		[ $? -ne 0 ] && { color "下载 ${MYSQL_FIlE}文件失败" 1; exit; }
	fi
}

install() {
	color "开始安装 MySQL-${MYSQL_VERSION}" 0
	if id mysql &> /dev/null; then
		color "mysql 用户已存在" 1
	else
		useradd -s /sbin/nologin -r mysql
		color "创建用户" 0
	fi
    lib_location=$(find / -name "libncurses.so.5" 2>/dev/null)
    if [ -z "$lib_location" ]; then
        color "libncurses.so.5 not found, attempting to install..." 1;
        if [ $ID == "centos" ]; then
            #yum update -y
            yum makecache
            yum install ncurses-compat-libs -y
        elif [ $ID == "rocky" ]; then
            #yum update -y
            yum makecache
            yum install ncurses-compat-libs -y
        else
            apt update
            apt -y install libncurses5
        fi

    lib_location=$(find / -name "libncurses.so.5" 2>/dev/null)
        if [ -z "$lib_location" ]; then
            color "Failed to install libncurses.so.5" 1
            exit 1
        else
            color "libncurses.so.5 installed successfully." 0
        fi
     else
        color "libncurses.so.5 found at $lib_location" 0
    fi
	cd $SRC_DIR
	tar xf ${MYSQL_FILE}
    ln -s `echo $MYSQL_FILE | awk -F'.' '{print $1"."$2"."$3"."$4}'` mysql-${MYSQL_VERSION}
    mkdir -p /data/mysql${MYSQL_PORT}/{data,log,binlog,relaylog,run,tmp}
    ln -s ${SRC_DIR}/mysql-${MYSQL_VERSION}/bin/mysql /usr/local/bin/mysql${MYSQL_PORT}
    ln -s ${SRC_DIR}/mysql-${MYSQL_VERSION}/bin/mysqld /usr/local/bin/mysqld${MYSQL_PORT}
    ln -s ${SRC_DIR}/mysql-${MYSQL_VERSION}/bin/mysqlbinlog /usr/local/bin/mysqlbinlog${MYSQL_PORT} 
    ln -s ${SRC_DIR}/mysql-${MYSQL_VERSION}/bin/mysqldump /usr/local/bin/mysqldump${MYSQL_PORT} 
    cat > /data/mysql${MYSQL_PORT}/my.cnf <<EOF 
[mysql]
socket=/data/mysql3306/run/mysql.sock


[mysqld]
port=${MYSQL_PORT}
mysqlx_port=${MYSQL_PORT}0

basedir=${SRC_DIR}/mysql-${MYSQL_VERSION}
lc_messages_dir=${SRC_DIR}/mysql-${MYSQL_VERSION}/share

datadir=/data/mysql${MYSQL_PORT}/data
tmpdir=/data/mysql${MYSQL_PORT}/tmp
log-error=/data/mysql${MYSQL_PORT}/log/alert.log
slow_query_log_file=/data/mysql${MYSQL_PORT}/log/slow.log
general_log_file=/data/mysql${MYSQL_PORT}/log/general.log
socket=/data/mysql${MYSQL_PORT}/run/mysql.sock
pid-file=/data/mysql${MYSQL_PORT}/run/mysqld.pid


innodb_data_file_path=ibdata1:128M:autoextend
innodb_buffer_pool_size=2G

EOF
    /${SRC_DIR}/mysql-${MYSQL_VERSION}/bin/mysqld --defaults-file=/data/mysql${MYSQL_PORT}/my.cnf --initialize
    chown -R mysql:mysql ${MYSQL_INSTALL_DIR}
	cat > /lib/systemd/system/mysql${MYSQL_PORT}.service <<EOF
[Unit]
Description=MySQL Community Server
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
User=mysql
Group=mysql
PIDFile=/data/mysql${MYSQL_PORT}/data/run/mysqld.pid
PermissionsStartOnly=true
#ExecStartPre=/usr/share/mysql/mysql-systemd-start pre
ExecStart=/usr/local/bin/mysqld${MYSQL_PORT} --defaults-file=/data/mysql${MYSQL_PORT}/my.cnf
TimeoutSec=infinity
Restart=on-failure
RuntimeDirectoryMode=755
LimitNOFILE=10000

# Set enviroment variable MYSQLD_PARENT_PID. This is required for restart.
Environment=MYSQLD_PARENT_PID=1

EOF

    systemctl daemon-reload
	systemctl enable --now mysql${MYSQL_PORT} &> /dev/null
	systemctl is-active mysql${MYSQL_PORT} &> /dev/null || { color "mysql 启动失败，退出!" 1; exit; }
	color "mysql安装完成" 0

}

reset_password() {
    INIT_PASSWD=`grep -i password /data/mysql${MYSQL_PORT}/log/alert.log |awk -F' ' '{print $NF}'`
    echo -e "\e[1;32m进入数据库：mysql${MYSQL_PORT} -uroot -h127.0.0.1 -p'${INIT_PASSWD}' -P${MYSQL_PORT}\e[0m" 
    echo -e "\033[1;32m进入数据库后修改密码: alter user 'root'@'localhost' identified by 'PASSWORD'\033[0m" 
}

check

install

reset_password
