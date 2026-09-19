# ShadowPlayer — App Store 提交材料包

> 这份文档包含提交时需要填写的**所有内容**，可以直接复制粘贴到 App Store Connect。
> 配套文档：[APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md)（合规检查清单）

---

## 版本 1.1 更新（当前待提交）

| 项 | 值 |
|---|---|
| 版本号 | **1.1** |
| Build 号 | **2** |
| 相比 1.0 | 新增单词释义（设备端翻译）、每个视频记住倍速、单词表界面重做；移除未实现的 Sync 按钮 |

### 本次更新说明（What's New，English — 直接复制）

```
Word meanings
Words you note can now show a meaning underneath. Translation runs entirely on your device, so nothing leaves your iPhone. Pick the audio language and the meaning language per playlist, so an English playlist and a Japanese one keep their own settings.

Playback speed is remembered
Each video reopens at the speed you last watched it.

A cleaner word list
Words and meanings now sit in a standard two-line row. Swipe to delete, and tapping Add word puts the cursor straight into the new row.

Fixes
- The video no longer shifts when the keyboard appears
- The speed selector is much easier to tap
- The list stays where you were after finishing input
```

### 本次更新说明（简体中文 — 直接复制）

```
单词释义
记录的单词下方可以显示释义。翻译完全在你的设备上完成，内容不会离开你的 iPhone。音频语言和释义语言可按播放列表分别设置，英语列表和日语列表互不影响。

记住播放倍速
每个视频都会以你上次观看的倍速重新打开。

更清爽的单词表
单词和释义采用标准的两行式排列。左滑即可删除，点击「Add word」后光标会直接落在新行上。

问题修复
- 键盘弹出时视频不再被顶动
- 倍速选择器更容易点中
- 输入完成后列表停留在原位
```

### 审核备注（App Review Notes，本次提交用）

```
ShadowPlayer plays videos from the user's own photo library. No account or login is required.

To test:
1. Launch the app and tap "Select Video"
2. Grant photo library access when prompted
3. Choose any video from the library
4. In the player, tap "Set A" and then "Set B" to create a repeating loop
5. Turn on "Show meanings" in the word list, tap "Add word", type a word, and tap Done — a meaning appears beneath it

New in this version: word meanings are produced by Apple's on-device Translation framework (iOS 18+). Nothing is sent off the device, and the app still makes no network requests of its own. On iOS 17 and earlier the feature is hidden entirely. The first use of a language pair may prompt the system to download that language.

The photo library permission is used only to read videos the user personally selects. The app never adds to, modifies, or deletes anything in the library.

Note: the device used for review must have at least one video in the photo library.
```

> ⚠️ 最后一句依然重要：审核设备相册里没有视频的话，审核员会看到空列表。

---

## 0. 我能做的 / 你必须自己做的

| 事项 | 谁来做 | 说明 |
|---|---|---|
| 隐私清单、代码合规修改 | ✅ 已完成 | 见下方「已完成的代码修改」 |
| 隐私政策页面 | ✅ 已完成 | `docs/privacy.html` |
| 支持页面 | ✅ 已完成 | `docs/support.html` |
| 落地页 | ✅ 已完成 | `docs/index.html` |
| App 描述、关键词、隐私标签答案 | ✅ 已完成 | 见下方，可直接复制 |
| **注册开发者账号** | ❌ **必须你本人** | 涉及身份认证、密码、$99 扣款，我不能代做 |
| **生成截图** | ✅ 我来做 | 用模拟器 + 无版权素材生成，见「截图」章节 |
| 在 App Store Connect 填表 | ❌ 你本人 | 需要登录你的账号 |

---

## 1. 已完成的代码修改（本次）

- ✅ 新增 `ShadowPlayer/PrivacyInfo.xcprivacy` —— 声明 `UserDefaults` 的 Required Reason API（`CA92.1`）。**不加这个上传会被自动拒**
- ✅ `TARGETED_DEVICE_FAMILY = 1` —— 仅 iPhone，移除 iPad 方向配置
- ✅ Bundle ID 改为 `com.liuyang19900520.shadowplayer` —— 反写域名，避免与他人冲突
- ✅ 「Sync Word List」按钮已**彻底删除**（1.1）—— 此前用 `#if DEBUG` 隐藏，现在连代码一并移除，不再有未实现的功能残留
- ✅ 相册权限层级加注释说明 —— `PHAccessLevel` 无只读级别，`.readWrite` 是读取相册的唯一选项
- ✅ Debug / Release 双配置构建通过，无错误无警告

---

## 2. 网站 — ✅ 已上线

网站已部署到你的 AWS 账号（`324971275476`）并通过 HTTPS 可访问。

### 线上网址（可直接填进 App Store Connect）

| 用途 | 网址 | 状态 |
|---|---|---|
| 隐私政策（必填） | `https://shadowplayer.liuyang19900520.com/privacy.html` | ✅ 200 |
| 支持网址（必填） | `https://shadowplayer.liuyang19900520.com/support.html` | ✅ 200 |
| 营销网址（选填） | `https://shadowplayer.liuyang19900520.com/` | ✅ 200 |

### 已创建的 AWS 资源

| 资源 | 标识 |
|---|---|
| S3 桶（私有） | `shadowplayer.liuyang19900520.com` |
| ACM 证书（us-east-1） | `075d8827-89d0-4baa-95f3-e0393e20b030` |
| CloudFront 分发 | `EOJATFWF8U3SJ` → `d2kw8li0le4l0e.cloudfront.net` |
| Origin Access Control | `ECNMRWOH6D14Y` |
| Route53 A 记录（别名） | `shadowplayer.liuyang19900520.com` |

架构与你已有的 `wallet.liuyang19900520.com` 一致：**S3 保持私有**，仅允许该 CloudFront
分发通过 OAC 读取；HTTP 自动 301 跳转 HTTPS；TLS 1.2+。

**成本**：约每月 $0.5 以内（这点流量基本落在 CloudFront 免费额度内）。

### 以后更新网页

改完 `docs/` 里的文件后执行：

```bash
./scripts/deploy-site.sh
```

脚本会同步到 S3 并清除 CloudFront 缓存。

---

## 3. App Store Connect 填写内容（可直接复制）

### 3.1 基本信息

| 字段 | 内容 |
|---|---|
| App 名称 | `ShadowPlayer` |
| 副标题（30 字符内） | `Loop any part of a video` |
| Bundle ID | `com.liuyang19900520.shadowplayer` |
| SKU | `shadowplayer-001` |
| 主要语言 | English (U.S.) |
| 主类别 | Education（教育） |
| 次类别 | Photo & Video（摄影与录像） |
| 年龄分级 | 4+ |
| 价格 | Free |

> ⚠️ **提交前先在 App Store Connect 搜索「ShadowPlayer」确认名称未被占用。**
> 若已被占用，备选：`Shadow Player - AB Loop`、`ABLoop Player`、`Shadowing Player`

### 3.2 App 描述（English）

```
ShadowPlayer is a minimalist video player built for one thing: repeating a section of a video until you've got it.

Perfect for shadowing practice, language learning, music transcription, or drilling any passage that needs repetition.

A-B REPEAT
Mark a start point and an end point. Playback loops between them indefinitely until you cancel. Both points are visible on the scrubber, so you always know exactly what's looping.

WORD LISTS
Jot down words as you practice. Each video keeps its own list, and you can review or edit it any time without leaving the player. Turn on meanings and each word gets a translation underneath, produced entirely on your device.

PLAYLISTS
Group related videos together. Open a playlist to see every video's words merged into a single editable list — handy for reviewing a whole lesson at once.

PLAYBACK BUILT FOR PRACTICE
• Speed from 0.8x to 1.2x with voice pitch kept natural, remembered per video
• Tap to jump 3 seconds, or press and hold to scan
• Resumes where you left off
• Audio keeps playing when the screen is locked
• Plays sound even with the silent switch on

COMPLETELY PRIVATE
No account. No network requests. No analytics. No ads. ShadowPlayer plays videos straight from your photo library and never copies or uploads them. Everything you create stays on your device.
```

### 3.3 App 描述（简体中文）

```
ShadowPlayer 是一款极简视频播放器，只专注做好一件事：把视频的某一段反复播放，直到你完全掌握。

适合影子跟读、语言学习、音乐扒谱，以及任何需要反复练习的场景。

A-B 循环
标记起点和终点，播放会在两点之间无限重复，直到你取消。A、B 两点在进度条上清晰可见，循环范围一目了然。

单词表
练习时随手记下生词。每个视频拥有独立的单词表，无需离开播放页即可查看和编辑。打开释义开关后，每个单词下方会显示译文，翻译完全在你的设备上完成。

播放列表
把相关视频归为一组。打开播放列表，可以把其中所有视频的单词合并成一份可编辑的总表，方便整课复习。

为练习而生的播放控制
• 0.8 倍至 1.2 倍速，音调保持自然，并按视频分别记住
• 点击跳转 3 秒，长按连续快进/快退
• 自动从上次结束的位置继续
• 锁屏后声音继续播放
• 静音键打开时依然有声音

完全私密
无需账号，无任何网络请求，无数据统计，无广告。ShadowPlayer 直接播放你相册中的视频，从不复制或上传。你创建的一切都只保存在自己的设备上。
```

### 3.4 关键词（100 字符以内，逗号分隔，不加空格）

```
loop,repeat,shadowing,language,practice,player,video,AB,study,listening,speaking,replay
```

### 3.5 更新说明（首个版本）

```
Initial release.
```

### 3.6 促销文本（170 字符内，选填，可随时修改）

```
Mark a start and end point, and let the section repeat while you practice. Built for shadowing and language study — completely private, no account needed.
```

---

## 4. App 隐私标签（App Privacy）填写答案

在 App Store Connect → App Privacy 中：

**问：Do you or your third-party partners collect data from this app?**
→ 选择 **No, we do not collect data from this app**

**依据**（如被问询可如此回复）：
- 全项目扫描确认**无任何网络请求代码**（无 `URLSession`、无第三方 SDK）
- 所有数据（最近播放、播放列表、单词表、播放进度）仅通过 `UserDefaults` 存储在设备本地
- 相册权限仅用于读取用户主动选择的视频，不上传、不复制

完成后隐私标签会显示为 **「Data Not Collected」**。

---

## 5. 导出合规（Export Compliance）

提交构建版本时会被询问加密相关问题：

| 问题 | 回答 |
|---|---|
| Does your app use encryption? | **No** |

> App 仅使用系统标准 API，不含自定义加密。选 No 后无需提交任何合规文件。
>
> 可选优化：在 `ShadowPlayer-Info.plist` 中加入 `ITSAppUsesNonExemptEncryption = false`，
> 这样以后每次上传都会自动跳过这个问题。需要的话告诉我，我来加。

---

## 6. 审核备注（App Review Notes）

建议在提交时填写，能显著降低被质询的概率：

```
ShadowPlayer plays videos from the user's own photo library. No account or login is required.

To test:
1. Launch the app and tap "Select Video"
2. Grant photo library access when prompted
3. Choose any video from the library
4. In the player, tap "Set A" and then "Set B" to create a repeating loop

The photo library permission is used only to read videos the user personally selects. The app never adds to, modifies, or deletes anything in the library, and makes no network requests.

Note: the simulator/device used for review must have at least one video in the photo library.
```

> ⚠️ **最后一句很重要**：审核设备如果相册里没有视频，审核员可能会看到空列表并误判为「功能无法使用」而拒绝。

---

## 7. 截图 — ✅ 已完成

5 张截图已生成，位于 **`screenshots/6.9-inch/`**，尺寸均为 **1320 × 2868**（App Store 6.9 吋规格）。
状态栏已统一为 Apple 规范的 9:41 样式，Release 构建截取。

| 文件 | 内容 | 建议顺序 |
|---|---|---|
| `02-player-ab.png` | **播放页：A-B 循环激活**（进度条上有 A/B 标记与循环区间）+ 单词表 | **1（主图）** |
| `01-home.png` | 首页：最近播放 + 播放列表 | 2 |
| `03-wordlist-ab.png` | 单词表编辑 + A/B 按钮激活态 | 3 |
| `04-playlist.png` | 播放列表详情 + Combined Word List 入口 | 4 |
| `05-combined-words.png` | 合并单词表（汇总列表内所有视频的词） | 5 |

> App Store Connect 只强制要求 **6.9 吋一组**，其余尺寸自动缩放，因此这一组即可提交。
> 详见 [screenshots/README.md](screenshots/README.md)。截图不入库（已加进 `.gitignore`），
> 需要重做时按该文档说明重新生成。

**素材说明**：截图中的视频是用 ffmpeg 生成的模拟日语课程画面（非真实版权内容），可安全用于商店展示。

---

## 8. 开发者账号注册指引（你本人操作，约 15 分钟）

> ⚠️ 我无法代你注册：涉及 Apple ID 密码认证和 $99 真实扣款。

1. 访问 <https://developer.apple.com/programs/enroll/>
2. 用你的 Apple ID 登录（建议用 `liuyang19900520@gmail.com`，与现有开发环境一致）
3. **实体类型选 Individual（个人）**
   - 个人：只需身份证/护照，审核快（通常 1–2 天）
   - 公司：需要 D-U-N-S 编号，流程长得多。你这种情况选个人即可
   - ⚠️ 注意：个人账号在 App Store 上显示的开发者名称是**你的真实姓名**
4. 填写个人信息（姓名需与证件一致）
5. 支付 **$99 USD/年**
6. 等待审核邮件

### 账号通过后要做的

1. Xcode → Settings → Accounts → 用同一 Apple ID 登录
2. 项目 → Signing & Capabilities → 确认 Team
   （Apple 会把原有的个人团队**原地升级**为付费会员，Team ID 不变，仍是 `3T7MJA53W9`，
   因此工程无需改动；签名有效期自动从 7 天变为 1 年）
3. 在 App Store Connect 创建 App 记录，Bundle ID 选 `com.liuyang19900520.shadowplayer`

---

## 9. 提交流程速查

```
1. Xcode 中 Team 切换为付费账号
2. 确认 Build 号递增（当前 CURRENT_PROJECT_VERSION = 1）
3. 顶部设备选 "Any iOS Device (arm64)"
4. Product → Archive
5. Organizer → Distribute App → App Store Connect → Upload
6. 等待处理完成（约 10–30 分钟，会收到邮件）
7. App Store Connect 填写本文档第 3–6 节的内容 + 上传截图
8. 提交审核
```

**预期审核时长**：24–48 小时。本 App 风险点少，一次过审概率较高。
