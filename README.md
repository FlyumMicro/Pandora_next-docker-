# Pandora_next-docker-
Pandora_next docker  Successfully deployed

昨天潘多拉的旧版本一直用不了 ，上了github搜索了一下看到 pandora-next 的版本

![Untitled](http://qinapi.yuefuture.top/img/20231122162442.png?img/)

 安装教程走一直没成功 问问了开发者说不要用docker搭建

我自己本地搭建了一下居然成功了

![Untitled](http://qinapi.yuefuture.top/img/20231122162534.png?img/)

那就很奇怪，然后我没用docker搭建还是一直失败启动不起来

![Untitled](http://qinapi.yuefuture.top/img/20231122162545.png?img/)

日志一直报错 license 这个文件问题

![Untitled](http://qinapi.yuefuture.top/img/20231122162606.png?img/)

已经是按照这个下载下来的配置 不知道为啥本地搭建成功了 服务器没成功

映射目录到容器内的`/data`目录，`config.json`、`tokens.json`和`license.jwt`放在其中

![Untitled](http://qinapi.yuefuture.top/img/20231122162636.png?img/)


docker搭建在配置文件中加入  ‘volumes:’ 注意必须加入不然后面会因为没有配置文件报错 

映射目录到容器内的`/data`目录，`config.json`、`tokens.json`和`license.jwt`放在其中

1.先在目录下创建 `docker-compose.yml` 按照自己的 ‘volumes’  配置

```jsx
version: '3'
services:
  pandora-next:
    image: pengzhile/pandora-next
    container_name: PandoraNext
    network_mode: bridge
    restart: always
    ports:
      - "8899:8181"
    environment:
      - PANDORA_NEXT_LICENSE=${LICENSE_TOKEN}
    volumes:
      - /home/yue/docker_obj/ChatPandoraNov:/chat/data
```

2.创建`job.sh`

```jsx
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
```

上面job是为了 生成`license.jwt` 这个文件的

3.运行

```jsx
docker-compose up -d
```

搭建成功 是无法访问 ip+8899的

4.需要在运行 job.sh

```jsx
chmod 777 job.sh

./job.sh

```

![Untitled](http://qinapi.yuefuture.top/img/20231122162754.png?img/)

![Untitled](http://qinapi.yuefuture.top/img/20231122162803.png?img/)

这里的 `容器尚未启动，跳过执行 docker-compose down。`不管他

去看看日志

![Untitled](http://qinapi.yuefuture.top/img/20231122162814.png?img/)

1. 浏览器访问 ip+8899 输入token 就可以登录了

![Untitled](http://qinapi.yuefuture.top/img/20231122162825.png?img/)

出现这个 502 大概率就是 `license.jwt` 文件问题

![Untitled](http://qinapi.yuefuture.top/img/20231122162837.png?img/)
