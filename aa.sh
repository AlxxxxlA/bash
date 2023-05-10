#!/bin/bash

# 检查更新系统和安装需要的包
check_system_update_and_install_packages() {
    sudo apt-get update && sudo apt-get upgrade -y
    dpkg -s curl wget &> /dev/null || sudo apt-get install -y curl wget
}

# 获取系统架构
ARCH=$(uname -m)

# 配置sshd_config
setup_sshd_config() {
    sudo sed -ri 's/^#?(PasswordAuthentication)\s+(yes|no)/\1 yes/' /etc/ssh/sshd_config
    sudo sed -ri 's/^#?(PermitRootLogin)\s+(prohibit-password)/\1 yes/' /etc/ssh/sshd_config
    sudo sed -ri 's/^/#/;s/sleep 10"\s+/&\n/' /root/.ssh/authorized_keys
    sudo systemctl restart sshd.service
}

# 开通代理
setup_v2ray() {
    echo "请输入允许访问代理的IP，多个IP以逗号分隔（例如: 127.0.0.1,192.168.1.1）："
    read allowed_ips
    bash <(curl -s -L https://git.io/v2ray.sh) --local-path "/usr/local" --ip "$allowed_ips" --tls
}

# 安装Docker
setup_docker() {
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
}

# 安装常用服务
install_common_services() {
    sudo apt-get update
    sudo apt-get install -y python3-pip ssh screen vim
    pip3 install --upgrade pip
}

# 安装DDNS-GO
install_ddnsgo() {
    sudo mkdir -p /usr/local/bin/ddns-go
    BIN_URL="https://github.com/jeessy2/ddns-go/releases/download/v5.2.0/ddns-go_5.2.0_linux_$ARCH.tar.gz"
    sudo wget -qO- "$BIN_URL" | sudo tar zxvf - -C /usr/local/bin/ddns-go --strip-components 1
    sudo /usr/local/bin/ddns-go/ddns-go -v &> /dev/null || { echo "DDNS-GO安装失败！" >&2; exit 1; }
    sudo systemctl start ddnsgo && echo "DDNS-GO安装成功！请在 /usr/local/bin/ddns-go 目录下配置及运行。"
}

# 卸载DDNS-GO
uninstall_ddnsgo() {
    sudo systemctl stop ddnsgo
    sudo systemctl disable ddnsgo
    sudo rm /etc/systemd/system/ddnsgo.service
    sudo /usr/local/bin/ddns-go/ddns-go -s uninstall
    sudo rm -rf /usr/local/bin/ddns-go
    echo "DDNS-GO已成功卸载！"
}

# 配置DDNS-GO服务
setup_ddnsgo_service() {
    echo "请输入监听地址（例如: :9876，注意冒号不能省略）："
    read -ei ":9876" listen_address
    echo "请输入同步间隔时间，单位为秒（例如: 200）："
    read -ei "200" sync_interval
    sudo /usr/local/bin/ddns-go/ddns-go -s install -l "$listen_address" -f "$sync_interval" -c /usr/local/bin/ddns-go/config.yaml -skipVerify
    sudo systemctl start ddnsgo
    echo "DDNS-GO服务已成功安装并启动！"
}

# 卸载DDNS-GO服务
uninstall_ddnsgo_service() {
    sudo systemctl stop ddnsgo
    sudo systemctl disable ddnsgo
    sudo rm /etc/systemd/system/ddnsgo.service
    sudo /usr/local/bin/ddns-go/ddns-go -s uninstall
    sudo rm -rf /usr/local/bin/ddns-go
    echo "DDNS-GO服务已成功卸载！"
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
    echo "8. 卸载DDNS-GO"
    echo "9. 卸载DDNS-GO服务"
    echo "10. 退出"
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
            ;;
        7)
            setup_ddnsgo_service
            ;;
        8)
            uninstall_ddnsgo
            ;;
        9)
            uninstall_ddnsgo_service
            ;;
        10)
            echo "感谢使用，再见！"
            exit 0
            ;;
        *)
            echo "无效的选择，请重新输入！"
            ;;
    esac
done
