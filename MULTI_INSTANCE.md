# TNTIP 多實例部署指南

本指南詳細說明如何部署多個 TNTIP 挖礦實例。由於每個 IP 地址只能運行一個 TNTIP 節點，多實例部署需要為每個實例配置不同的公共 IP 地址。

## 重要注意事項

⚠️ **IP 地址限制**: 一個公共 IP 地址只能運行一個 TNTIP 節點  
⚠️ **容器命名**: 多實例部署時，每個實例的容器名稱必須唯一  
⚠️ **註冊要求**: 每個實例都需要使用邀請碼 `PBU2MBAY` 註冊的不同帳號

## 三種網路配置選項

### 選項 1: HTTP 代理 (已支援)

使用 HTTP 代理服務器為每個實例提供不同的出口 IP。

#### 配置方法

**透過命令行參數**:
```bash
sudo ./tntip.sh start -u user1@example.com -p pass1 \
  --proxy-enable true \
  --proxy-host http://proxy1.example.com:8080 \
  --proxy-user proxyuser1 \
  --proxy-pass proxypass1 \
  --port 50011 \
  -d ./data1
```

**透過環境變數**:
```bash
# 在 .env 文件中設置
PROXY_ENABLE="true"
PROXY_HOST="http://proxy1.example.com:8080"
PROXY_USER="proxyuser1"
PROXY_PASS="proxypass1"
```

### 選項 2: MACVLAN 網路 (直接分配公共 IP)

使用 Docker 的 MACVLAN 網路驅動程式直接為容器分配公共 IP 地址。

#### 前置需求

1. 您需要擁有多個可用的公共 IP 地址
2. 網路環境支援 MACVLAN (某些雲服務提供商可能不支援)

#### 設定步驟

**步驟 1: 創建 MACVLAN 網路**
```bash
# 創建 MACVLAN 網路 (請根據您的網路環境調整參數)
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  tntip-macvlan
```

**步驟 2: 使用 MACVLAN 配置啟動實例**
```bash
# 啟動第一個實例
sudo ./tntip.sh start -u user1@example.com -p pass1 \
  --network-mode macvlan \
  --network-name tntip-macvlan \
  --static-ip 192.168.1.10 \
  --container-name tntip-instance1 \
  --port 50010 \
  -d ./data1

# 啟動第二個實例
sudo ./tntip.sh start -u user2@example.com -p pass2 \
  --network-mode macvlan \
  --network-name tntip-macvlan \
  --static-ip 192.168.1.11 \
  --container-name tntip-instance2 \
  --port 50010 \
  -d ./data2
```

#### MACVLAN 配置文件範例

建立 `docker-compose-macvlan.yml`:
```yaml
services:
  tntip:
    image: aron666/tntip
    container_name: tntip-instance1
    environment:
      - TNT_USER=${TNT_USER}
      - TNT_PASS=${TNT_PASS}
      - ADMIN_USER=${ADMIN_USER:-admin}
      - ADMIN_PASS=${ADMIN_PASS:-admin}
    volumes:
      - "${DATA_DIR:-./data}:/app/UserData"
    restart: always
    networks:
      tntip-macvlan:
        ipv4_address: 192.168.1.10
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:50010 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

networks:
  tntip-macvlan:
    external: true
```

### 選項 3: SOCKS5 代理 (使用 tun2proxy)

使用 tun2proxy 和 SOCKS5 代理為每個實例提供不同的出口 IP。

#### 配置方法

**環境變數設置**:
```bash
# 在 .env 文件中添加
SOCKS5_ENABLE="true"
SOCKS5_PROXY="socks5://username:password@host:port"
# 或不帶認證
SOCKS5_PROXY="socks5://host:port"
```

#### SOCKS5 配置文件範例

建立 `docker-compose-socks5.yml`:
```yaml
services:
  tun2proxy:
    volumes:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv6.conf.default.disable_ipv6=0
    cap_add:
      - NET_ADMIN
    container_name: tun2proxy-instance1
    image: ghcr.io/tun2proxy/tun2proxy-ubuntu:latest
    command: --proxy ${SOCKS5_PROXY}
    restart: always

  tntip:
    image: aron666/tntip
    container_name: tntip-instance1
    environment:
      - TNT_USER=${TNT_USER}
      - TNT_PASS=${TNT_PASS}
      - ADMIN_USER=${ADMIN_USER:-admin}
      - ADMIN_PASS=${ADMIN_PASS:-admin}
    volumes:
      - "${DATA_DIR:-./data}:/app/UserData"
    network_mode: "service:tun2proxy"
    depends_on:
      - tun2proxy
    restart: always
```

#### SOCKS5 實例啟動範例

```bash
# 第一個實例
sudo ./tntip.sh start -u user1@example.com -p pass1 \
  --socks5-enable true \
  --socks5-proxy "socks5://user1:pass1@proxy1.example.com:1080" \
  --container-name tntip-instance1 \
  --compose-file docker-compose-socks5-1.yml \
  -d ./data1

# 第二個實例  
sudo ./tntip.sh start -u user2@example.com -p pass2 \
  --socks5-enable true \
  --socks5-proxy "socks5://user2:pass2@proxy2.example.com:1080" \
  --container-name tntip-instance2 \
  --compose-file docker-compose-socks5-2.yml \
  -d ./data2
```

## 多實例部署最佳實踐

### 目錄結構規劃

建議為每個實例創建獨立的目錄：

```
tntip-multi/
├── instance1/
│   ├── .env
│   ├── docker-compose.yml
│   ├── data/
│   └── logs/
├── instance2/
│   ├── .env
│   ├── docker-compose.yml
│   ├── data/
│   └── logs/
└── instance3/
    ├── .env
    ├── docker-compose.yml
    ├── data/
    └── logs/
```

### 自動化部署腳本

建立 `deploy-multi.sh`:
```bash
#!/bin/bash

# 實例配置陣列
instances=(
  "user1@example.com:pass1:50011:./data1:tntip-instance1"
  "user2@example.com:pass2:50012:./data2:tntip-instance2"
  "user3@example.com:pass3:50013:./data3:tntip-instance3"
)

for instance in "${instances[@]}"; do
  IFS=':' read -r user pass port data_dir container_name <<< "$instance"
  
  echo "部署實例: $container_name"
  sudo ./tntip.sh start \
    -u "$user" \
    -p "$pass" \
    --port "$port" \
    -d "$data_dir" \
    --container-name "$container_name" \
    --proxy-enable true \
    --proxy-host "http://proxy$((${#container_name} % 3 + 1)).example.com:8080"
  
  sleep 10
done
```

### 容器命名規範

為避免容器名稱衝突，建議使用以下命名規範：

```bash
# 基本格式
tntip-instance-{編號}
tntip-{用戶名}-{編號}
tntip-{區域}-{編號}

# 範例
tntip-instance-1
tntip-instance-2
tntip-alice-1
tntip-bob-1
tntip-asia-1
tntip-europe-1
```

### 端口分配

建議為每個實例分配不同的端口：

```bash
# 實例 1: 50011
# 實例 2: 50012  
# 實例 3: 50013
# 依此類推...
```

### 監控和管理

**查看所有實例狀態**:
```bash
# 查看所有 TNTIP 容器
docker ps -f name=tntip

# 查看所有實例日誌
for container in $(docker ps -f name=tntip --format "{{.Names}}"); do
  echo "=== $container ==="
  docker logs --tail 50 "$container"
done
```

**批量管理操作**:
```bash
# 停止所有實例
docker stop $(docker ps -f name=tntip -q)

# 重啟所有實例
docker restart $(docker ps -f name=tntip -q)

# 更新所有實例
docker compose -f docker-compose-instance1.yml pull
docker compose -f docker-compose-instance2.yml pull
# ... 重複其他實例
```

## 故障排除

### 常見問題

**問題 1: IP 衝突**
```bash
# 檢查 IP 是否已被使用
ping -c 1 192.168.1.10

# 查看 Docker 網路配置
docker network inspect tntip-macvlan
```

**問題 2: 容器名稱衝突**
```bash
# 檢查現有容器
docker ps -a

# 移除衝突的容器
docker rm -f tntip-instance1
```

**問題 3: 代理連接失敗**
```bash
# 測試代理連接
curl --proxy http://proxy1.example.com:8080 http://httpbin.org/ip

# 檢查代理設置
docker exec tntip-instance1 env | grep PROXY
```

**問題 4: SOCKS5 代理問題**
```bash
# 檢查 tun2proxy 容器狀態
docker logs tun2proxy-instance1

# 測試 SOCKS5 連接
docker exec tntip-instance1 curl --socks5 socks5://proxy:1080 http://httpbin.org/ip
```

### 日誌收集

```bash
# 收集所有實例日誌
mkdir -p logs
for container in $(docker ps -f name=tntip --format "{{.Names}}"); do
  docker logs "$container" > "logs/${container}.log" 2>&1
done
```

### 效能監控

```bash
# 監控所有實例資源使用
docker stats $(docker ps -f name=tntip -q)

# 查看網路使用情況
docker exec tntip-instance1 cat /proc/net/dev
```

## 注意事項

1. **IP 地址需求**: 確保您有足夠的公共 IP 地址用於多實例部署
2. **資源需求**: 每個實例都會消耗系統資源，請確保主機有足夠的 CPU 和記憶體
3. **網路頻寬**: 多實例會增加網路頻寬使用量
4. **代理服務**: 確保您的代理服務支援並發連接
5. **註冊帳號**: 每個實例需要使用不同的註冊帳號
6. **定期維護**: 定期檢查實例狀態和日誌

## 效能優化建議

1. **硬體配置**: 建議每 3-5 個實例配置 1 個 CPU 核心和 1GB 記憶體
2. **磁碟 I/O**: 使用 SSD 硬碟以獲得更好的效能
3. **網路配置**: 使用高品質的網路連接和代理服務
4. **監控設置**: 設置監控系統以追蹤實例效能和收益

這個多實例部署指南提供了三種不同的網路配置選項，您可以根據自己的需求和網路環境選擇最適合的方案。