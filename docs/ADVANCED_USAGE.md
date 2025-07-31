# TNTIP 進階用法指南

本文檔包含 TNTIP 挖礦服務的進階配置選項、故障排除和管理功能。

---

## 進階指令選項

### 互動式選單

不帶參數執行腳本將顯示互動式選單：

```bash
sudo ./tntip.sh
```

選單選項：
1. 啟動 TNTIP 服務
2. 停止 TNTIP 服務
3. 更新 TNTIP 服務
4. 配置 TNTIP 服務
5. 查看 Docker 日誌
0. 退出

---

## 配置文件

### .env 檔案

腳本會在根目錄生成 `.env` 配置文件，包含以下設置：

```env
TNT_USER="your_email@example.com"
TNT_PASS="your_password"
ADMIN_USER="admin"
ADMIN_PASS="admin"
DATA_DIR="./data"
TNTIP_PORT="50010"
```

### docker-compose.yml

服務使用 Docker Compose 進行容器編排，包含：
- **tntip**: TNTIP 挖礦主服務

### 數據目錄結構

```
./data/
└── (TNTIP 用戶數據)
```

---

## 服務訪問

啟動成功後，可以通過以下方式訪問 TNTIP 服務：

- **Web 界面**: http://localhost:50010 (或您自定義的端口)
- **管理界面**: 使用配置的管理員帳號登入

---

## 疑難排解

### Docker 相關問題

**問題**: Docker 安裝失敗
```bash
# 解決方案: 使用 -i 參數重新安裝
sudo ./tntip.sh start -i

# 中國大陸地區使用中國鏡像源
sudo ./tntip.sh start -i cn
```

**問題**: Docker Compose 無法使用
```bash
# 檢查 Docker 版本
docker --version

# 檢查 Docker Compose
docker compose version

# 如果版本過舊，重新安裝 Docker
sudo ./tntip.sh start -i
```

### 服務啟動問題

**問題**: 服務無法啟動
```bash
# 1. 檢查配置文件
cat .env

# 2. 查看 Docker 日誌
sudo ./tntip.sh logs

# 3. 檢查容器狀態
docker compose ps

# 4. 重新配置服務
sudo ./tntip.sh config
```

**問題**: 端口衝突
```bash
# 檢查端口佔用
netstat -tlnp | grep 50010

# 停止衝突的服務或修改端口
sudo ./tntip.sh config --port 50011
```

### 註冊和登入問題

**問題**: 無法登入 TNTIP
```bash
# 1. 確認已使用邀請碼註冊
# 註冊連結: https://edge.titannet.info/signup?inviteCode=PBU2MBAY

# 2. 檢查 Email 和密碼是否正確
sudo ./tntip.sh config -u your@email.com -p yourpassword

# 3. 重新啟動服務
sudo ./tntip.sh stop
sudo ./tntip.sh start
```

**問題**: 邀請碼錯誤
```bash
# 確保使用正確的邀請碼: PBU2MBAY
# 重新註冊: https://edge.titannet.info/signup?inviteCode=PBU2MBAY
```

### 網路連接問題

**問題**: 無法連接到 TNTIP 網路
```bash
# 1. 檢查網路連接
ping edge.titannet.info

# 2. 檢查防火牆設置
sudo ufw status
sudo firewall-cmd --list-all

# 3. 檢查 Email 和密碼是否正確
sudo ./tntip.sh config
```

### 日誌查看問題

**問題**: 看不到日誌
```bash
# 1. 確認服務是否已啟動
docker compose ps

# 2. 檢查容器日誌
docker logs tntip

# 3. 如果是新安裝，等待幾分鐘讓服務完全啟動
```

**問題**: 日誌顯示錯誤
```bash
# 常見錯誤及解決方案:

# 錯誤: "Invalid credentials"
# 解決: 重新配置正確的 Email 和密碼
sudo ./tntip.sh config -u 正確的Email -p 正確的密碼

# 錯誤: "Network connection failed"
# 解決: 檢查網路連接和防火牆設置

# 錯誤: "Permission denied"
# 解決: 確保使用 root 權限運行腳本
sudo ./tntip.sh start
```

### 配置問題

**問題**: 配置文件損壞或丟失
```bash
# 重新生成配置文件
sudo ./tntip.sh config

# 手動檢查配置文件
cat .env
cat docker-compose.yml
```

**問題**: 數據目錄權限問題
```bash
# 修復數據目錄權限
sudo chown -R root:root ./data
sudo chmod -R 755 ./data
```

### 更新問題

**問題**: 更新失敗
```bash
# 1. 手動停止服務
sudo ./tntip.sh stop

# 2. 清理舊映像
docker system prune -f

# 3. 重新啟動
sudo ./tntip.sh start
```

---

## 進階使用

### 自動重啟設置

服務已配置為自動重啟，但如果需要系統級別的自動啟動：

```bash
# 創建 systemd 服務文件
sudo cat > /etc/systemd/system/tntip.service << EOF
[Unit]
Description=TNTIP Mining Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/tntip.sh start
ExecStop=$(pwd)/tntip.sh stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# 啟用服務
sudo systemctl enable tntip.service
sudo systemctl start tntip.service
```

### 監控和維護

```bash
# 查看資源使用情況
docker stats

# 檢查磁碟使用
du -sh ./data

# 備份配置文件
cp .env .env.backup
cp docker-compose.yml docker-compose.yml.backup

# 清理 Docker 系統
docker system prune -f
```

### 多實例部署

如果需要運行多個 TNTIP 實例，請參考詳細的多實例部署指南：

📖 **[多實例部署指南](../MULTI_INSTANCE.md)**

該指南包含：
- **三種網路配置選項**: HTTP 代理、MACVLAN、SOCKS5 代理
- **完整配置範例**: 包含 docker-compose 配置和環境變數設置
- **自動化部署腳本**: 批量部署和管理多個實例
- **故障排除**: 常見問題和解決方案

⚠️ **重要提醒**: 由於每個 IP 地址只能運行一個 TNTIP 節點，多實例部署必須為每個實例配置不同的公共 IP 地址。

---

## 注意事項

- ⚠️ **此腳本需要 root 權限才能執行**
- ⚠️ **必須使用邀請碼 PBU2MBAY 註冊帳號才能使用 TNTIP**
- ⚠️ **請確保 Email 和密碼的正確性**
- ⚠️ **定期備份數據目錄以防資料丟失**
- ⚠️ **確保防火牆允許所需端口的連接**
- ⚠️ **建議在穩定的網路環境下運行**

---

## 支援與回饋

如果您在使用過程中遇到問題，請：

1. 首先查看本文檔的疑難排解部分
2. 確認已使用邀請碼 `PBU2MBAY` 正確註冊
3. 檢查 GitHub Issues 中是否有類似問題
4. 提供詳細的錯誤信息和系統環境信息

---

## 更新日誌

- **v1.0.0**: 初始版本發布，支援基本的 TNTIP 服務管理功能

---

<div align="center">

**感謝使用 TNTIP 挖礦服務管理腳本！**

**記得使用邀請碼 PBU2MBAY 註冊哦！**

</div>