# App Store 提交资料

每次提交一个文件夹，文件夹名就是版本号。各版本通用的参考信息（账号、网站、隐私标签答案、导出合规）在 [../APP_STORE_SUBMISSION.md](../APP_STORE_SUBMISSION.md)。

## 版本索引

| 版本 | 构建号 | 内容 | 状态 |
|---|---|---|---|
| [1.3](1.3/) | 4 | 摇一摇录入、长内容折行、改词重新翻译 | ⏳ 准备提交 |
| [1.2](1.2/) | 3 | 改名 Kage Loop、视频命名、单词表入口 | ✅ 2026-09-28 发布 |
| [1.1](1.1/) | 2 | 单词释义（设备端翻译）、记住倍速 | ✅ 已发布 |
| 1.0 | 1 | 首个版本（名为 A-B Looper ShadowPlayer） | ✅ 2026-09 发布，资料未单独存档 |

## 每个版本文件夹的结构

```
<版本号>/
├── README.md            改了什么、提交前检查、逐步操作、提交记录
├── review-notes.txt     App 审核信息 → 备注（英文）
├── en/  ja/  zh-Hans/   一个语言一个文件夹，对应 App Store Connect 右上角的语言下拉
│   ├── whats-new.txt         此版本的新增内容
│   ├── description.txt       描述
│   ├── keywords.txt          关键词
│   ├── promotional-text.txt  促销文本
│   └── subtitle.txt          副标题（在「App 信息」页）
└── screenshots/6.9-inch/  按上传顺序编号的截图
```

在 App Store Connect 切到哪个语言，就打开哪个语言的文件夹，逐个复制。

## 字数上限

| 字段 | 上限 |
|---|---|
| 副标题 | 30 |
| 关键词 | 100（逗号分隔、不加空格；App 名里的词苹果会自动索引，不用重复写） |
| 促销文本 | 170（不用审核，随时可改） |
| 此版本的新增内容 / 描述 | 4000 |

## 新建一个版本的文件夹

1. 复制上一个版本的文件夹，改名为新版本号
2. 改 `README.md` 里的版本号、改动和步骤
3. 重写三种语言的 `whats-new.txt`；功能有变化的话，同步改 `description.txt`
4. 截图界面有变化就重拍，没变化可以沿用（git 按内容存储，相同的图片不会重复占空间）
5. 在上面的「版本索引」里加一行

## 截图规格与重新生成

- **6.9 英寸，1320 × 2868**：App Store Connect 只强制要求这一组，其余尺寸自动缩放
- 用 iPhone 17 Pro Max 模拟器的 **Release** 构建截取，状态栏统一为 9:41
- 截图里的视频必须是自己生成的、无版权的素材

步骤：

1. 用 ffmpeg 生成素材视频（模拟日语课程画面）。文字里**不要包含撇号**（`'`），否则会破坏 drawtext 的转义，把滤镜字符串渲染进画面
2. 导入模拟器相册：`xcrun simctl addmedia <sim> lesson.mp4`
3. 设置状态栏：
   ```bash
   xcrun simctl status_bar <sim> override --time "9:41" --wifiMode active --wifiBars 3 \
     --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
   ```
4. 需要预置剧集名或单词表时，**先关机再改 plist**：模拟器运行时，`cfprefsd` 会用缓存把直接写入的值覆盖回去
   ```bash
   xcrun simctl shutdown <sim>
   # 编辑 .../Data/Application/<uuid>/Library/Preferences/com.liuyang19900520.shadowplayer.plist
   xcrun simctl boot <sim>
   ```
   注意 `xcrun simctl spawn <sim> defaults read` 读的是模拟器全局的配置域，**不是** App 沙盒里的那份
5. 播放页的控件 5 秒后自动隐藏，摇一摇提示条 8 秒后消失：在同一条命令里**连拍多张**，再挑合适的那张
6. 摇一摇提示条在模拟器里出不来（模拟器跑不了语音模型），拍那张图时临时把 `LoopCaptureAvailability.makeSource()` 换成返回固定文字的假实现，**拍完一定要恢复**
