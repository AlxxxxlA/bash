#!/bin/bash

# 检查更新系统和安装需要的包
check_system_update_and_install_packages() {
    apt-get update && apt-get upgrade -y
    dpkg -s curl wget &> /dev/null || apt-get install -y curl wget
}

# 获取系统架构
ARCH=$(uname -m)

# 配置sshd_config
setup_sshd_config() {
    sed -ri 's/^#?(PasswordAuthentication)\s+(yes|no)/\1 yes/' /etc/ssh/sshd_config
    sed -ri 's/^#?(PermitRootLogin)\s+(prohibit-password)/\1 yes/' /etc/ssh/sshd_config
    sed -ri 's/^/#/;s/sleep 10"\s+/&\n/' /root/.ssh/authorized_keys
    service sshd restart
}

# 开通代理
setup_v2ray() {
    bash <(curl -s -L https://git.io/v2ray.sh)
}

# 安装Docker
setup_docker() {
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
}

# 安装常用服务
install_common_services() {
    apt-get update
    apt-get install -y python3-pip ssh screen
    pip3 install --upgrade pip
}

# 安装DDNS-GO
install_ddnsgo() {
    sudo mkdir -p /usr/local/bin/ddns-go
    BIN_URL="https://github.com/jeessy2/ddns-go/releases/download/v5.2.0/ddns-go_5.2.0_$ARCH.tar.gz"
    sudo wget -O /usr/local/bin/ddns-go/ddns-go.tar.gz "$BIN_URL"
    sudo tar zxvf /usr/local/bin/ddns-go/ddns-go.tar.gz -C /usr/local/bin/ddns-go/
    sudo /usr/local/bin/ddns-go/ddns-go -c /usr/local/bin/ddns-go/config.yaml &
}

# 配置DDNS-GO服务
setup_ddnsgo_service() {
    echo "请输入监听地址（例如: :9876，注意冒号不能省略）"
    read listen_address
    echo "请输入同步间隔时间，单位为秒（例如: 600）"
    read sync_interval
    echo "请输入自定义配置文件路径（例如: /usr/local/bin/ddns-go/config.yaml）"
    read custom_config_path
    echo "请输入参数（例如: -skipVerify）"
    read parameters

    # 安装服务
    sudo /usr/local/bin/ddns-go/ddns-go -s install -l "$listen_address" -f "$sync_interval" -c "$custom_config_path" $parameters
    
    # 启动服务
    sudo systemctl start ddnsgo
    echo "DDNS-GO服务已成功安装并启动！"
}

# 菜单
while true; do
    echo "请选择需要执行的操作："
    echo "1. 更新系统和安装必要软件包"
    echo "2. 配置sshd_config"
    echo "3. 开通代理"
    echo "4. 安装Docker"
    echo "5. 安装常用服务"
    echo "6. 安装DDNS-GO"
    echo "7. 配置DDNS-GO服务"
    echo "8. 退出"
    read choice

    case $choice in
        1)
            check_system_update_and_install_packages
            echo "系统更新和必要软件包安装完成！"
            ;;
        2)
            setup_sshd_config
            echo "sshd_config配置完成！"
            ;;
        3)
            setup_v2ray
            echo "代理已开通！"
            ;;
        4)
            setup_docker
            echo "Docker安装完成！"
            ;;
        5)
            install_common_services
            echo "常用服务安装完成！"
            ;;
        6)
            install_ddnsgo
            echo "DDNS-GO安装完成！"
            ;;
        7)
            setup_ddnsgo_service
            ;;
        8)
            echo "感谢使用，再见！"
            exit 0
            ;;
        *)
            echo "无效的选择，请重新输入！"
            ;;
    esac
done
