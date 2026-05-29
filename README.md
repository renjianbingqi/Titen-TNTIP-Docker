![Total Visitors](https://komarev.com/ghpvc/?username=caobianhe-tntip&color=green)
# TNTIP 挖礦服務管理腳本

一鍵部署和管理 TNTIP 挖礦服務的自動化腳本，支援 Docker 容器化部署，提供完整的服務生命週期管理。

TNTIP 是一個瀏覽器挖礦插件，已經被容器化為 Docker 映像，讓部署和管理變得更加簡單。

---

## 白名單/需要邀請碼註冊

**⚠️ 註冊要求**: 使用 TNTIP 挖礦程式需要透過指定邀請碼註冊的帳號才可以使用。

**註冊連結**: https://edge.titannet.info/signup?inviteCode=VJAJ9NRR

**邀請碼**: `VJAJ9NRR`

請先完成註冊，然後使用註冊的 Email 和密碼配置本腳本。

---

## 快速部署/啟動

### 中國區域快速部署

```bash
# 下載並快速啟動
git clone https://github.com/aron-666/Titen-TNTIP-Docker.git tntip
cd tntip
chmod +x tntip.sh

# 中國區域快速啟動
sudo ./tntip.sh start -u 你的Email -p 你的密碼 -i cn
```

### 其他區域快速部署

```bash
# 下載並快速啟動
git clone https://github.com/aron-666/Titen-TNTIP-Docker.git tntip
cd tntip
chmod +x tntip.sh

# 其他區域快速啟動
sudo ./tntip.sh start -u 你的Email -p 你的密碼 -i
```

> **注意**: 
> - `-i cn` 參數用於在中國區域安裝 Docker 時使用中國鏡像源
> - Email 和密碼需要是在 https://edge.titannet.info 上註冊的帳號
> - 註冊時必須使用邀請碼: `VJAJ9NRR`

---

## 參數說明

### 基本指令

```bash
./tntip.sh [指令] [選項]
```

- `start`: 啟動 TNTIP 服務
- `stop`: 停止 TNTIP 服務
- `update`: 更新 TNTIP 服務到最新版本
- `config`: 配置 TNTIP 服務
- `logs`: 查看 Docker 容器日誌

### 全局選項

- `-i, --install [cn]`: 自動安裝 Docker 環境
  - 不帶參數: 使用國際源
  - 帶 `cn` 參數: 使用中國源
- `-u, --tnt-user EMAIL`: 指定 TNTIP 註冊的 Email
- `-p, --tnt-pass PASSWORD`: 指定 TNTIP 註冊的密碼
- `--admin-user USERNAME`: 指定管理員用戶名 (預設: admin)
- `--admin-pass PASSWORD`: 指定管理員密碼 (預設: admin)
- `-d, --data-dir PATH`: 指定數據目錄 (預設: ./data)
- `--port PORT`: 指定服務端口 (預設: 50010)

### 啟動服務範例

```bash
# 中國區域
sudo ./tntip.sh start -u your@email.com -p yourpassword -i cn

# 其他區域
sudo ./tntip.sh start -u your@email.com -p yourpassword -i

# 自定義管理員和數據目錄
sudo ./tntip.sh start -u your@email.com -p yourpassword --admin-user myuser --admin-pass mypass -d /opt/tntip-data
```

---

## 進階用法 (Advanced Usage)

如需了解更多進階配置選項、故障排除和管理功能，請參考：

📖 **[進階用法指南](docs/ADVANCED_USAGE.md)**

該指南包含：
- **互動式選單**：無參數運行腳本的選單界面
- **配置文件詳解**：.env 文件和 docker-compose.yml 配置
- **疑難排解**：Docker、服務啟動、網路連接等問題解決方案
- **進階使用**：自動重啟設置、監控維護、多實例部署
- **系統整合**：systemd 服務配置和系統級管理

---

## 社群貢獻與感謝

感謝社群成員 [@Amelia_Node](https://medium.com/@Amelia_Node) 撰寫的詳細教學文章：

📝 **[Titan Browser Extension TNTIP 插件掛機獨家方案（Docker Compose版）— 適用於Linux端](https://medium.com/@Amelia_Node/titan-browser-extension-tntip-%E6%8F%92%E4%BB%B6%E6%8C%82%E6%9C%BA%E7%8B%AC%E5%AE%B6%E6%96%B9%E6%A1%88docker-compose%E7%89%88-%E9%80%82%E7%94%A8%E4%BA%8Elinux%E7%AB%AF-2acc331165c2)**

這篇文章提供了額外的部署指南和使用心得，對於想要深入了解 TNTIP Docker 部署的用戶來說是很好的參考資料。

---

<div align="center">

**感謝使用 TNTIP 挖礦服務管理腳本！**

**記得使用邀請碼 VJAJ9NRR 註冊哦！**

</div>