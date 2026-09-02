[🇨🇳 中文](README.md) | [🇺🇸 English](README_EN.md)

<p align="center">
  <img src="assets/ico/MinecraftHTMLview.png" width="120" alt="Minecraft HTMLViewer 图标" />
</p>

# Minecraft HTMLViewer

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/your-username/htmlviewer?style=social)](https://github.com/your-username/htmlviewer/stargazers)

**一款 Minecraft 像素风格的 Android HTML 查看器与前端调试工具——在手机上打开、阅读、调试你的网页，就像在方块世界里探索地图一样。**

它不只是一个"打开 HTML"的 WebView 壳：内置源码阅读器、Console 调试台、ZIP 项目管理与系统分享，配合 Minecraft 风格的像素 UI、开箱动画与经验条加载遮罩，让移动端前端调试也有"打怪升级"的乐趣。

## 功能特性

- [x] HTML 预览：本地文件 / SAF 文件夹直开，支持同目录相对资源（CSS / JS / 图片）
- [x] 源码阅读器：HTML / CSS / JS / JSON / Markdown 语法高亮 + Minecraft 配色（XP 绿、钻石蓝、金、红石红）
- [x] 源码工具箱：行号侧栏、文件内搜索（大小写不敏感、上下跳转、命中计数）、字号调节、自动换行开关
- [x] Console 调试台：劫持 `console.log / warn / error`、捕获 `window.onerror` 与未处理的 Promise 拒绝，按等级着色、长按复制、一键清空
- [x] 项目管理：ZIP 一键导入（含路径穿越防护、入口 HTML 自动探测）、项目打包导出、系统分享面板分发
- [x] 浏览记录：最近文件与项目双列表、可配置上限（5 / 10 / 20 / 50）、独立收藏夹
- [x] 文件感知：打开过的文件被外部修改后，回到应用自动提示"发现文件已更新"；文件被删除则显示"这个区块已经不存在了"错误页
- [x] 阅读体验：Minecraft 开箱式页面转场、Loading World 加载遮罩、全屏模式、返回键优先回退网页历史
- [x] 平板适配：≥600dp 侧边导航栏，≥700dp 预览 / 源码左右分栏
- [x] 设置中心：JavaScript 开关、外部网络访问开关、阅读偏好（字号 / 换行 / 行号 / 默认标签页）、设置导出 / 导入 / 恢复默认

> 注意：页面加载早期（`DOMContentLoaded` 之前）触发的 console 输出可能无法捕获；关闭 JavaScript 后 Console 功能同步停用。

## 安装与使用

### 1. 环境要求

| 依赖 | 版本 |
| ---- | ---- |
| Flutter SDK | 3.27.x |
| Dart SDK | ^3.6.0 |
| Android Studio + Android SDK | AGP 8.1.1+，minSdk 由模板决定 |
| Android 设备 / 模拟器 | Android 5.0+ |

### 2. 获取源码并安装依赖

```bash
git clone https://github.com/your-username/htmlviewer.git
cd htmlviewer
flutter pub get
```

### 3. 配置签名（可选，仅发布构建需要）

仓库不包含签名文件。本地调试直接跳过此步；如需构建 release 包，在 `android/` 下创建 `key.properties`：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=你的别名
storeFile=../app/your-release-key.jks
```

> `key.properties` 与 `*.jks` 已列入 `.gitignore`，请勿提交到仓库。

### 4. 运行与构建

```bash
# 连接设备后直接运行
flutter run

# 构建 release APK
flutter build apk --release
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。

## 技术栈

| 技术名称 | 用途 | 版本 |
| -------- | ---- | ---- |
| Flutter | 跨平台 UI 框架 | 3.27.x / Dart ^3.6.0 |
| flutter_riverpod | 状态管理与依赖注入 | ^2.6.1 |
| webview_flutter (+_android) | HTML 页面渲染 | ^4.10.0 |
| highlight | 纯 Dart 语法高亮（无原生依赖） | ^0.7.0 |
| archive | ZIP 项目导入 / 导出 | ^3.6.1 |
| file_picker | Android SAF 文件与文件夹选择 | ^8.1.6 |
| share_plus | 系统分享面板（文件 / ZIP） | ^10.1.4 |
| path_provider | 应用工作目录（解压项目） | ^2.1.4 |
| shared_preferences | 设置 / 历史 / 收藏持久化 | ^2.3.4 |
| flutter_launcher_icons | 自适应应用图标生成 | ^0.14.3 |
| Press Start 2P | 像素标题字体（OFL 协议内置） | - |

## 项目结构

```text
htmlviewer/
├── lib/
│   ├── main.dart                       # 入口：初始化持久化并启动 App
│   ├── app/                            # 应用骨架
│   │   ├── app.dart                    # MaterialApp 与路由
│   │   ├── root_shell.dart             # 底部导航 / NavigationRail 外壳
│   │   ├── theme.dart                  # Minecraft 配色与主题
│   │   └── chest_page_transition.dart  # 开箱式页面转场动画
│   ├── core/
│   │   └── services/                   # file_picker / zip / share 服务封装
│   ├── data/models/html_entry.dart     # 文件与项目数据模型
│   ├── features/
│   │   ├── home/                       # 首页
│   │   ├── files/                      # 文件列表、历史控制器、打开流程
│   │   ├── favorites/                  # 收藏页
│   │   ├── viewer/                     # WebView 预览页（预览 / 源码双标签）
│   │   ├── source/                     # 源码阅读器与语法高亮
│   │   ├── developer/                  # Console 调试台
│   │   └── settings/                   # 设置模型 / 控制器 / 页面
│   ├── storage/                        # settings / history 存储层
│   └── widgets/                        # 像素组件库（按钮 / 卡片 / 图标 / 进度条）
├── test/                               # 单元与组件测试
├── assets/
│   ├── fonts/                          # Press Start 2P 字体（OFL）
│   └── ico/                            # 应用图标源图
└── android/                            # Android 工程与签名配置
```

## 效果截图 / 演示

<p align="center">
  <img src="assets/ico/MinecraftHTMLview.png" width="96" alt="应用图标" />
</p>

> 截图整理中：实机截图将陆续补充到 `docs/screenshots/` 目录（首页、预览 / 源码分栏、Console 调试台、ZIP 导入流程等）。

## License

本项目采用 [MIT License](LICENSE) 发布。

内置的 Press Start 2P 字体（`assets/fonts/PressStart2P-Regular.ttf`）遵循 [SIL Open Font License 1.1](https://openfontlicense.org/)，可随应用自由分发。

## 贡献指南

欢迎提交 Issue 与 Pull Request！

**Issue 格式要求**

- Bug 报告请包含：复现步骤、预期行为 / 实际行为、设备型号与 Android 版本、（可选）控制台报错截图
- 功能请求请说明：使用场景、期望的交互方式、为什么现有功能不能满足

**Pull Request 流程**

1. Fork 本仓库
2. 新建分支：`git checkout -b feat/your-feature`（修复用 `fix/`，文档用 `docs/`）
3. 提交更改：`git commit -m "feat: 简要描述"`
4. 推送并创建 PR，描述改动内容与测试方式
5. 等待 Review，通过后合并
