#!/bin/bash

# 定义源配置文件的路径
CURRENT_SOURCE="/etc/apt/sources.list"

# 定义源列表
SOURCES=(
    "https://mirrors.aliyun.com"
    "https://mirrors.huaweicloud.com"
    "https://mirrors.ustc.edu.cn"
    "https://mirrors.tuna.tsinghua.edu.cn"
    "https://mirrors.sohu.com"
    "https://mirrors.163.com"
    "https://mirrors.tencent.com/"
    "http://archive.ubuntu.com"
)

# 显示当前使用的源
echo "当前使用的源是:"
cat $CURRENT_SOURCE

# 提示用户选择要切换的源
echo "请选择要切换的源:"
for i in "${!SOURCES[@]}"; do 
    echo "$((i+1)). ${SOURCES[$i]}"
done

read -p "输入你的选择: " choice

# 检查输入是否有效
if [[ $choice -lt 1 || $choice -gt ${#SOURCES[@]} ]]; then
    echo "无效的选择，请输入 1 或 2"
    exit 1
fi

# 获取用户选择的源
selected_source=${SOURCES[$((choice-1))]}

# 生成新的 sources.list 内容
new_sources_list="deb $selected_source/ubuntu/ $(lsb_release -cs) main universe
deb $selected_source/ubuntu/ $(lsb_release -cs)-updates restricted multiverse
deb $selected_source/ubuntu/ $(lsb_release -cs)-security main universe
deb $selected_source/ubuntu/ $(lsb_release -cs)-backports restricted multiverse"

# 备份当前的 sources.list
sudo cp $CURRENT_SOURCE $CURRENT_SOURCE.`date +%F`

# 写入新的 sources.list
echo "$new_sources_list" | sudo tee $CURRENT_SOURCE > /dev/null

# 更新 APT 缓存
sudo apt-get update

echo "已切换到 $selected_source，并已更新 APT 缓存。"
