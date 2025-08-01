# SOCKS5 代理批量部署配置說明

這個配置文件用於批量部署多個 SOCKS5 代理服務。每個物件代表一個要建立的 SOCKS5 代理服務容器。

## 配置文件格式

配置文件應為 JSON 格式的陣列，每個元素包含以下欄位：

- `container_name`: (字串) 要建立的容器名稱
- `username`: (字串) SOCKS5 代理的認證使用者名稱  
- `password`: (字串) SOCKS5 代理的認證密碼
- `port`: (數字) 為此代理服務分配的對外連接埠
- `socks5_connection`: (字串) SOCKS5 的連線資訊 URL

## 使用方法

1. 編輯 `config.json` 文件，配置您的代理服務資訊
2. 執行部署腳本：
   ```bash
   sudo ./multi-deploy.sh deploy-socks5
   ```
   
   或指定自定義配置文件：
   ```bash
   sudo ./multi-deploy.sh deploy-socks5 my-config.json
   ```

## 範例配置

```json
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
```

## 注意事項

- 確保每個容器名稱都是唯一的
- 確保每個端口都是唯一的，避免衝突
- SOCKS5 連線 URL 格式：`socks5://[username:password@]host:port`
- 請確保您的 SOCKS5 代理服務器可以正常訪問