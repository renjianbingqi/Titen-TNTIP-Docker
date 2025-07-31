#!/bin/bash

# TNTIP 多實例部署管理腳本

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 檢查 root 權限
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}錯誤: 此腳本需要 root 權限才能執行${NC}"
        echo -e "${YELLOW}請使用 sudo 或以 root 用戶身份運行此腳本${NC}"
        exit 1
    fi
}

# 創建 MACVLAN 網路
create_macvlan_network() {
    local network_name="${1:-tntip-macvlan}"
    local subnet="${2:-192.168.1.0/24}"
    local gateway="${3:-192.168.1.1}"
    local parent_interface="${4:-eth0}"
    
    echo -e "${BLUE}創建 MACVLAN 網路: $network_name${NC}"
    echo -e "${YELLOW}子網: $subnet${NC}"
    echo -e "${YELLOW}網關: $gateway${NC}"
    echo -e "${YELLOW}父接口: $parent_interface${NC}"
    
    if docker network ls | grep -q "$network_name"; then
        echo -e "${YELLOW}網路 $network_name 已存在${NC}"
        return 0
    fi
    
    docker network create -d macvlan \
        --subnet="$subnet" \
        --gateway="$gateway" \
        -o parent="$parent_interface" \
        "$network_name"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}MACVLAN 網路創建成功${NC}"
    else
        echo -e "${RED}MACVLAN 網路創建失敗${NC}"
        return 1
    fi
}

# 部署多個實例
deploy_multiple_instances() {
    echo -e "${BLUE}批量部署多個 TNTIP 實例${NC}"
    
    # 實例配置範例
    local instances=(
        "user1@example.com:pass1:50011:./data1:tntip-instance1:http://proxy1.example.com:8080"
        "user2@example.com:pass2:50012:./data2:tntip-instance2:http://proxy2.example.com:8080"
        "user3@example.com:pass3:50013:./data3:tntip-instance3:http://proxy3.example.com:8080"
    )
    
    echo -e "${YELLOW}注意: 請修改腳本中的實例配置以符合您的需求${NC}"
    read -p "是否繼續部署範例實例? (y/n): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        echo -e "${BLUE}部署已取消${NC}"
        return 0
    fi
    
    for instance in "${instances[@]}"; do
        IFS=':' read -r user pass port data_dir container_name proxy_host <<< "$instance"
        
        echo -e "${BLUE}部署實例: $container_name${NC}"
        
        # 創建實例目錄
        mkdir -p "$(dirname "$data_dir")"
        
        # 啟動實例
        ./tntip.sh start \
            -u "$user" \
            -p "$pass" \
            --port "$port" \
            -d "$data_dir" \
            --container-name "$container_name" \
            --proxy-enable true \
            --proxy-host "$proxy_host"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}實例 $container_name 部署成功${NC}"
        else
            echo -e "${RED}實例 $container_name 部署失敗${NC}"
        fi
        
        sleep 5
    done
}

# 部署 MACVLAN 實例
deploy_macvlan_instances() {
    echo -e "${BLUE}部署 MACVLAN 多實例${NC}"
    
    # 檢查是否已創建 MACVLAN 網路
    if ! docker network ls | grep -q "tntip-macvlan"; then
        echo -e "${YELLOW}需要先創建 MACVLAN 網路${NC}"
        read -p "請輸入子網 (預設: 192.168.1.0/24): " subnet
        read -p "請輸入網關 (預設: 192.168.1.1): " gateway
        read -p "請輸入父接口 (預設: eth0): " parent_interface
        
        create_macvlan_network "tntip-macvlan" "${subnet:-192.168.1.0/24}" "${gateway:-192.168.1.1}" "${parent_interface:-eth0}"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}MACVLAN 網路創建失敗，無法繼續${NC}"
            return 1
        fi
    fi
    
    # MACVLAN 實例配置
    local macvlan_instances=(
        "user1@example.com:pass1:./data1:tntip-macvlan1:192.168.1.10"
        "user2@example.com:pass2:./data2:tntip-macvlan2:192.168.1.11"
        "user3@example.com:pass3:./data3:tntip-macvlan3:192.168.1.12"
    )
    
    echo -e "${YELLOW}注意: 請修改腳本中的 IP 配置以符合您的網路環境${NC}"
    read -p "是否繼續部署 MACVLAN 實例? (y/n): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        echo -e "${BLUE}部署已取消${NC}"
        return 0
    fi
    
    for instance in "${macvlan_instances[@]}"; do
        IFS=':' read -r user pass data_dir container_name static_ip <<< "$instance"
        
        echo -e "${BLUE}部署 MACVLAN 實例: $container_name (IP: $static_ip)${NC}"
        
        # 創建實例目錄
        mkdir -p "$(dirname "$data_dir")"
        
        # 啟動 MACVLAN 實例
        ./tntip.sh start \
            -u "$user" \
            -p "$pass" \
            -d "$data_dir" \
            --container-name "$container_name" \
            --network-mode macvlan \
            --network-name tntip-macvlan \
            --static-ip "$static_ip"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}MACVLAN 實例 $container_name 部署成功${NC}"
        else
            echo -e "${RED}MACVLAN 實例 $container_name 部署失敗${NC}"
        fi
        
        sleep 5
    done
}

# 部署 SOCKS5 實例 (從 JSON 配置文件讀取)
deploy_socks5_instances() {
    echo -e "${BLUE}部署 SOCKS5 多實例${NC}"
    
    local config_file="${1:-config.json}"
    
    # 檢查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}錯誤: 配置文件 $config_file 不存在${NC}"
        echo -e "${YELLOW}請先創建配置文件，範例：${NC}"
        cat << 'EOF'
[
  {
    "container_name": "socks_proxy_01",
    "username": "user1",
    "password": "password123",
    "port": 1080,
    "socks5_connection": "socks5://user1:pass1@proxy1.example.com:1080"
  },
  {
    "container_name": "socks_proxy_02",
    "username": "user2",
    "password": "password456",
    "port": 1081,
    "socks5_connection": "socks5://user2:pass2@proxy2.example.com:1080"
  }
]
EOF
        return 1
    fi
    
    # 檢查 jq 是否可用
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}錯誤: 需要安裝 jq 來解析 JSON 配置文件${NC}"
        echo -e "${YELLOW}請安裝 jq: sudo apt update && sudo apt install -y jq${NC}"
        return 1
    fi
    
    # 驗證 JSON 格式
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}錯誤: 配置文件 $config_file 不是有效的 JSON 格式${NC}"
        return 1
    fi
    
    # 獲取實例數量
    local instance_count=$(jq '. | length' "$config_file")
    echo -e "${BLUE}從 $config_file 讀取到 $instance_count 個 SOCKS5 代理配置${NC}"
    
    # 顯示將要部署的配置
    echo -e "${YELLOW}將要部署的實例:${NC}"
    jq -r '.[] | "  - 容器名稱: \(.container_name), 用戶: \(.username), 端口: \(.port)"' "$config_file"
    
    read -p "是否繼續部署這些 SOCKS5 實例? (y/n): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        echo -e "${BLUE}部署已取消${NC}"
        return 0
    fi
    
    # 逐一處理每個實例
    for i in $(seq 0 $((instance_count - 1))); do
        # 從 JSON 提取實例配置
        local container_name=$(jq -r ".[$i].container_name" "$config_file")
        local username=$(jq -r ".[$i].username" "$config_file")
        local password=$(jq -r ".[$i].password" "$config_file")
        local port=$(jq -r ".[$i].port" "$config_file")
        local socks5_connection=$(jq -r ".[$i].socks5_connection" "$config_file")
        
        echo -e "${BLUE}部署 SOCKS5 實例 $((i + 1))/$instance_count: $container_name${NC}"
        
        # 創建實例專用的數據目錄
        local data_dir="./data_${container_name}"
        mkdir -p "$data_dir"
        
        # 啟動 SOCKS5 實例
        ./tntip.sh start \
            -u "$username@example.com" \
            -p "$password" \
            -d "$data_dir" \
            --container-name "$container_name" \
            --port "$port" \
            --socks5-enable true \
            --socks5-proxy "$socks5_connection"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}SOCKS5 實例 $container_name 部署成功${NC}"
        else
            echo -e "${RED}SOCKS5 實例 $container_name 部署失敗${NC}"
        fi
        
        sleep 5
    done
    
    echo -e "${GREEN}所有 SOCKS5 實例部署完成${NC}"
}

# 查看所有實例狀態
show_all_instances() {
    echo -e "${BLUE}查看所有 TNTIP 實例狀態${NC}"
    
    # 查看所有 TNTIP 容器
    echo -e "${YELLOW}所有 TNTIP 容器:${NC}"
    docker ps -f name=tntip --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo
    echo -e "${YELLOW}tun2proxy 容器:${NC}"
    docker ps -f name=tun2proxy --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 停止所有實例
stop_all_instances() {
    echo -e "${RED}停止所有 TNTIP 實例${NC}"
    
    read -p "確定要停止所有 TNTIP 實例嗎? (y/n): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        echo -e "${BLUE}操作已取消${NC}"
        return 0
    fi
    
    # 停止所有 TNTIP 容器
    local tntip_containers=$(docker ps -f name=tntip -q)
    if [[ -n "$tntip_containers" ]]; then
        echo -e "${BLUE}停止 TNTIP 容器...${NC}"
        docker stop $tntip_containers
    fi
    
    # 停止所有 tun2proxy 容器
    local tun2proxy_containers=$(docker ps -f name=tun2proxy -q)
    if [[ -n "$tun2proxy_containers" ]]; then
        echo -e "${BLUE}停止 tun2proxy 容器...${NC}"
        docker stop $tun2proxy_containers
    fi
    
    echo -e "${GREEN}所有實例已停止${NC}"
}

# 顯示選單
show_menu() {
    clear
    echo "========================================"
    echo "        TNTIP 多實例部署管理選單        "
    echo "========================================"
    echo "1. 創建 MACVLAN 網路"
    echo "2. 部署 HTTP 代理多實例"
    echo "3. 部署 MACVLAN 多實例"
    echo "4. 部署 SOCKS5 多實例 (從 config.json)"
    echo "5. 查看所有實例狀態"
    echo "6. 停止所有實例"
    echo "0. 退出"
    echo "========================================"
}

# 處理選單選擇
handle_menu_choice() {
    case "$1" in
        1)
            create_macvlan_network
            ;;
        2)
            deploy_multiple_instances
            ;;
        3)
            deploy_macvlan_instances
            ;;
        4)
            deploy_socks5_instances
            ;;
        5)
            show_all_instances
            ;;
        6)
            stop_all_instances
            ;;
        0)
            echo "感謝使用！再見！"
            exit 0
            ;;
        *)
            echo -e "${RED}錯誤：無效的選擇，請重新輸入${NC}"
            ;;
    esac
    
    # 顯示「按任意鍵返回選單」提示（除非選擇了退出選項）
    if [[ "$1" != "0" ]]; then
        echo
        read -n 1 -s -r -p "按任意鍵返回選單..."
        echo
        show_menu
        read -p "請選擇操作 [0-6]: " choice
        handle_menu_choice "$choice"
    fi
}

# 主程序
main() {
    check_root_privileges
    
    if [[ $# -eq 0 ]]; then
        show_menu
        read -p "請選擇操作 [0-6]: " choice
        handle_menu_choice "$choice"
    else
        case "$1" in
            create-macvlan)
                create_macvlan_network "$2" "$3" "$4" "$5"
                ;;
            deploy-http)
                deploy_multiple_instances
                ;;
            deploy-macvlan)
                deploy_macvlan_instances
                ;;
            deploy-socks5)
                deploy_socks5_instances "$2"
                ;;
            status)
                show_all_instances
                ;;
            stop-all)
                stop_all_instances
                ;;
            *)
                echo "用法: $0 [指令] [選項]"
                echo
                echo "指令:"
                echo "  create-macvlan [子網] [網關] [接口] [網路名稱]"
                echo "                                     創建 MACVLAN 網路"
                echo "  deploy-http                        部署 HTTP 代理多實例"
                echo "  deploy-macvlan                     部署 MACVLAN 多實例"
                echo "  deploy-socks5 [配置文件]           部署 SOCKS5 多實例 (預設: config.json)"
                echo "  status                             查看所有實例狀態"
                echo "  stop-all                           停止所有實例"
                echo
                echo "範例:"
                echo "  $0 deploy-socks5                   # 使用預設的 config.json"
                echo "  $0 deploy-socks5 my-config.json   # 使用自定義配置文件"
                exit 1
                ;;
        esac
    fi
}

# 執行主程序
main "$@"