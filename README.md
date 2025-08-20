# dst-dst
**Don't Starve Together Dedicated Server Tool**  
简称 **DST-DST** 🎮 — 一个用于快速搭建和管理饥荒联机版专用服务器的脚本工具。    

---
## ✨ 功能特性
- 🚀 一键安装 SteamCMD、游戏依赖和 DST 服务端
- 👤 自动创建 `steam` 用户运行steamCMD和游戏进程
- 💾 支持添加 **Swap（虚拟内存）**
- 📑 根据游戏存档检查游戏mod并添加
- 🌍 支持多世界部署
- 🎨 彩色终端提示，简洁直观

---

## 📦 安装与使用
### 前提条件
- 操作系统：**Ubuntu**
- 权限：**root** 或`sudo` 

### 执行方法

**本地clone + 执行**
```bash
# 克隆仓库
git clone https://github.com/shiwivi/dst-dst.git
cd dst-dst

# 赋予执行权限
chmod +x dst-dst.sh

# 运行脚本
./dst-dst.sh
```
或

**快速执行**
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/shiwivi/dst-dst/main/dst-dst.sh)"
```

### 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
