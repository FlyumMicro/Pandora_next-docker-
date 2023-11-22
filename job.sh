#!/bin/bash

# 定义保存上一次 IPv4 地址的文件路径
ip_file=".ip"

# 获取当前机器的 IPv4 地址
get_current_ip() {
  local current_ip=""
  local websites=("https://myip4.ipip.net" "https://ddns.oray.com/checkip" "https://ip.3322.net" "https://4.ipw.cn")

  for website in "${websites[@]}"; do
    current_ip=$(curl -s "$website" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    if [ -n "$current_ip" ]; then
      break
    fi
  done

  echo "$current_ip"
}

# 更新环境变量并重启容器
update_container() {
  # 检查容器状态
  if docker ps -f name=PandoraNext| grep -q "Up"; then

    # 停止并移除容器
    docker-compose down

    # 等待容器停止
    while docker ps -f name=PandoraNext | grep -q "Up"; do
      sleep 1
    done

    # 重新启动容器
    docker-compose up -d
  else
    echo "容器尚未启动，跳过执行 docker-compose down。"
    # 启动容器
    docker-compose up -d
  fi
}

update_env(){
    # 请求最新的环境变量并保存到文件
    curl -fL "https://dash.pandoranext.com/data/ZNfWPD6xz60gqTZpf-b2gLi2Ek-k2hqu9jfYL5FQP6E/license.jwt" > license.jwt

    # 从文件中读取环境变量的值
    local token=$(cat license.jwt)

    # 设置环境变量到 Docker Compose 文件中
    echo "LICENSE_TOKEN=${token}" > .env
}

# 获取当前 IPv4 地址
current_ip=$(get_current_ip)

# 检查是否成功获取到 IPv4 地址
if [ -n "$current_ip" ]; then
  # 检查是否存在保存的 IPv4 地址文件
  if [ -f "$ip_file" ]; then
    # 读取上一次保存的 IPv4 地址
    previous_ip=$(cat "$ip_file")

    # 比较当前地址和上一次地址是否相同
    if [ "$current_ip" != "$previous_ip" ]; then
      update_env

      update_container

      # 保存当前 IPv4 地址到文件
      echo "$current_ip" > "$ip_file"
    else
      echo "IPv4 地址未改变，结束脚本执行。"
    fi
  else
    update_env

    update_container

    # 保存当前 IPv4 地址到文件
    echo "$current_ip" > "$ip_file"
  fi
else
  echo "无法获取当前机器的 IPv4 地址。"
fi
