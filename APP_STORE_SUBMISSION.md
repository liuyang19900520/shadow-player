# Kage Loop — App Store 提交材料包

> 这份文档包含提交时需要填写的**所有内容**，可以直接复制粘贴到 App Store Connect。
> 配套文档：[APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md)（合规检查清单）

---

## 版本 1.2 更新（当前待提交）—— 含改名

| 项 | 值 |
|---|---|
| 版本号 | **1.2** |
| Build 号 | **3** |
| **App 名称** | `A-B Looper ShadowPlayer` → **`Kage Loop`** |
| Bundle ID | `com.liuyang19900520.shadowplayer`（**不变**，改名不影响） |
| 相比 1.1 | 视频/播放列表可命名、独立的单词表入口（两级）、Recent 显示所属列表；移除 Combined Word List；修复进度条与翻译两个问题 |

### 改名说明（重要前提）

改名分三处，**必须同时改**，否则商店名和手机上显示的名字会对不上：

| 位置 | 改什么 | 状态 |
|---|---|---|
| App Store 商店名 | App Store Connect → App Information → Name | ❌ 你本人操作（见第 10 节） |
| 手机主屏图标名 | `CFBundleDisplayName` | ✅ 已改为 `Kage Loop` |
| App 内标题 / 锁屏播放信息 | `navigationTitle`、`MPMediaItemPropertyTitle` | ✅ 已改为 `Kage Loop` |

名称可用性已核查（iTunes Search API，美区 + 日区）：`Kage Loop` 未被占用。

### 各语言名称与副标题（直接复制）

| 语言 | 名称（30 字符内） | 副标题（30 字符内） |
|---|---|---|
| English (U.S.)（主要语言） | `Kage Loop` | `A-B repeat for shadowing` |
| 日本語 | `Kage Loop` | `シャドーイング用 A-B リピート` |
| 简体中文 | `Kage Loop` | `极简 A-B 循环跟读播放器` |

> 名称三种语言保持一致，便于搜索与口碑传播；副标题按语言本地化。

### 本次更新说明（What's New，English — 直接复制）

```
A new name
The app is now called Kage Loop. Same app, same everything you saved — just a name that says what it does.

Name your videos and playlists
Videos take their filename automatically, and you can rename any video or playlist by swiping on it. Episodes now read in order — 02 before 10 — so a lesson series is easy to follow.

Word lists have their own home
A new Word Lists button on the home screen opens every list you have kept, grouped by playlist and then by episode. Notes stay even after you delete the video from your photo library, so you can free up space without losing your words.

Recent shows where a video came from
Each recent video now names the playlist it belongs to, and Recent holds four videos instead of three.

Fixes
- The scrubber no longer jumps away from your finger while dragging
- Tapping Done now translates right away, instead of only after reopening the video
```

### 本次更新说明（简体中文 — 直接复制）

```
新名字
App 更名为 Kage Loop。功能和你保存的内容完全不变，只是换了一个更贴切、更好搜的名字。

给视频和播放列表命名
视频会自动采用文件名，也可以左滑重命名任意视频或播放列表。剧集按名称中的数字排序（02 排在 10 前面），一整套课程一目了然。

单词表有了独立入口
首页新增「单词表」按钮，按播放列表、再按剧集列出你记过的所有单词。即使把视频从相册中删除，单词表依然保留——可以放心清理存储空间。

最近播放显示来源
最近播放的每个视频会标注所属的播放列表，数量从 3 个增加到 4 个。

问题修复
- 拖动进度条时圆点不再与手指错位
- 点击 Done 立即翻译，不必退出视频再进来
```

### 本次更新说明（日本語 — 直接复制）

```
新しい名前
アプリ名が Kage Loop になりました。機能も保存したデータもそのままです。

動画とプレイリストに名前を付けられます
動画はファイル名を自動で表示します。スワイプすれば動画もプレイリストも自由に名前を変更できます。エピソードは名前の数字順（02 が 10 より先）に並びます。

単語リスト専用の入口
ホーム画面の「単語リスト」から、保存したすべてのリストをプレイリスト別・エピソード別に開けます。写真から動画を削除しても単語はそのまま残るので、安心して空き容量を作れます。

最近再生した動画の出どころを表示
最近再生した動画に、どのプレイリストのものかを表示するようになりました。表示件数も 3 件から 4 件に増えています。

修正
- シークバーのつまみがドラッグ中に指からずれなくなりました
- 「Done」をタップするとすぐに翻訳されるようになりました
```

### 审核备注（App Review Notes，1.2 提交用 — 直接复制）

```
Kage Loop (previously "A-B Looper ShadowPlayer") plays videos from the user's own photo library. No account or login is required. This version renames the app; the bundle identifier is unchanged.

To test:
1. Launch the app and tap "Select Video"
2. Grant photo library access when prompted
3. Choose any video from the library
4. In the player, tap "Set A" and then "Set B" to create a repeating loop
5. Turn on "Show meanings" in the word list, tap "Add word", type a word, and tap Done — a meaning appears beneath it
6. Go back to the home screen and tap the book icon in the top right to browse saved word lists

Word meanings are produced by Apple's on-device Translation framework (iOS 18+). Nothing is sent off the device, and the app still makes no network requests of its own. On iOS 17 and earlier the feature is hidden entirely. The first use of a language pair may prompt the system to download that language.

The photo library permission is used only to read videos the user personally selects. The app never adds to, modifies, or deletes anything in the library.

Note: the device used for review must have at least one video in the photo library.
```

> ⚠️ 最后一句依然重要：审核设备相册里没有视频的话，审核员会看到空列表。

---

<details>
<summary>版本 1.1 更新（已发布，存档）</summary>

## 版本 1.1 更新（已发布）

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

</details>

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
| **生成截图** | ✅ 我来做 | 用模拟器 + 无版权素材生成，见「截图」章节（1.2 已重拍） |
| **改名相关的代码/文档/网站改动** | ✅ 已完成（1.2） | 商店名仍需你在 ASC 手动改，见第 9 节阶段 C |
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
| App 名称 | `Kage Loop`（1.2 起；原 `A-B Looper ShadowPlayer`） |
| 副标题（30 字符内） | `A-B repeat for shadowing` |
| Bundle ID | `com.liuyang19900520.shadowplayer` |
| SKU | `shadowplayer-001` |
| 主要语言 | English (U.S.) |
| 主类别 | Education（教育） |
| 次类别 | Photo & Video（摄影与录像） |
| 年龄分级 | 4+ |
| 价格 | Free |

> ✅ `Kage Loop` 已核查未被占用（iTunes Search API，美区 + 日区，2026-09-27）。
> 若填写时仍提示被占用，备选：`Kage Repeat`、`Kageloop`、`Kage Loop Player`（均已核查为空）。

### 3.2 App 描述（English）

```
Kage Loop is a minimalist video player built for one thing: repeating a section of a video until you've got it.

Perfect for shadowing practice, language learning, music transcription, or drilling any passage that needs repetition.

A-B REPEAT
Mark a start point and an end point. Playback loops between them indefinitely until you cancel. Both points are visible on the scrubber, so you always know exactly what's looping.

WORD LISTS
Jot down words as you practice. Each video keeps its own list, and you can review or edit it any time without leaving the player. Turn on meanings and each word gets a translation underneath, produced entirely on your device.

Your notes outlive your videos. Word Lists on the home screen shows every list you have kept, grouped by playlist and then by episode — so you can delete a video to free up space and still have the words you learned from it.

PLAYLISTS
Group related videos together and name them. Videos take their filename automatically, and episodes sort the way you read them — 02 before 10.

PLAYBACK BUILT FOR PRACTICE
• Speed from 0.8x to 1.2x with voice pitch kept natural, remembered per video
• Tap to jump 3 seconds, or press and hold to scan
• Resumes where you left off
• Audio keeps playing when the screen is locked
• Plays sound even with the silent switch on

COMPLETELY PRIVATE
No account. No network requests. No analytics. No ads. Kage Loop plays videos straight from your photo library and never copies or uploads them. Everything you create stays on your device.
```

### 3.3 App 描述（简体中文）

```
Kage Loop 是一款极简视频播放器，只专注做好一件事：把视频的某一段反复播放，直到你完全掌握。

适合影子跟读、语言学习、音乐扒谱，以及任何需要反复练习的场景。

A-B 循环
标记起点和终点，播放会在两点之间无限重复，直到你取消。A、B 两点在进度条上清晰可见，循环范围一目了然。

单词表
练习时随手记下生词。每个视频拥有独立的单词表，无需离开播放页即可查看和编辑。打开释义开关后，每个单词下方会显示译文，翻译完全在你的设备上完成。

单词表比视频活得更久。首页的「单词表」会按播放列表、再按剧集列出你记过的所有单词——把视频删掉腾出空间，学过的词依然都在。

播放列表
把相关视频归为一组并命名。视频会自动采用文件名，剧集按名称中的数字排序（02 排在 10 前面）。

为练习而生的播放控制
• 0.8 倍至 1.2 倍速，音调保持自然，并按视频分别记住
• 点击跳转 3 秒，长按连续快进/快退
• 自动从上次结束的位置继续
• 锁屏后声音继续播放
• 静音键打开时依然有声音

完全私密
无需账号，无任何网络请求，无数据统计，无广告。Kage Loop 直接播放你相册中的视频，从不复制或上传。你创建的一切都只保存在自己的设备上。
```

### 3.4 关键词（100 字符以内，逗号分隔，不加空格）

```
kage,loop,repeat,shadowing,language,practice,player,video,AB,study,listening,speaking
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
> ✅ 已在 `ShadowPlayer-Info.plist` 中加入 `ITSAppUsesNonExemptEncryption = false`，
> 因此从 1.1 起每次上传都会自动跳过这个问题，**不会再弹出**。

---

## 6. 审核备注（App Review Notes）— 1.0 原始版本，存档

> ⚠️ **1.2 提交请用第 1 节里的版本**，下面这份是 1.0 时写的，没有提到翻译、单词表浏览器和改名。

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

## 7. 截图 — ✅ 已按 1.2 重拍

5 张截图位于 **`screenshots/6.9-inch/`**，尺寸均为 **1320 × 2868**（App Store 6.9 吋规格），
由 iPhone 17 Pro Max 模拟器 Release 构建（1.2 / build 3）截取，状态栏统一为 9:41。

| 文件 | 内容 | 上传顺序 |
|---|---|---|
| `01-player-ab.png` | **播放页：A-B 循环激活** —— 进度条上有 A/B 标记与循环区间，Set A / Set B 高亮，下方是带释义的单词表 | **1（主图）** |
| `02-home.png` | 首页：最近播放（含所属播放列表）+ 播放列表 + 右上角单词表入口 | 2 |
| `03-word-meanings.png` | 单集单词表：日语单词 + 中文释义 | 3 |
| `04-word-lists.png` | 单词表浏览器：播放列表 → 剧集两级 | 4 |
| `05-playlist.png` | 播放列表详情：剧集按 01 / 02 / 03 顺序排列 | 5 |

> ⚠️ **1.0 / 1.1 时的旧截图必须全部替换**：旧图顶部写着 `ShadowPlayer`，
> 且其中两张展示的是已经删除的 Combined Word List 功能。商店里留着不存在的功能截图，
> 是会被按 Guideline 2.3.3（截图与 App 不符）打回的。**上传时先删掉全部旧图再传新图。**

> App Store Connect 只强制要求 **6.9 吋一组**，其余尺寸自动缩放，因此这一组即可提交。
> 重新生成的方法见 [screenshots/README.md](screenshots/README.md)。截图不入库（已加进 `.gitignore`）。

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

## 9. 提交 1.2（改名版）的完整步骤

> 顺序很重要：**先改名，再传构建包**。名称是 App 级别的，构建包是版本级别的，
> 但同一次「提交审核」会把两者一起送审——改名和新版本必须在同一次提交里。

### 阶段 A — 我已经做完的（无需你操作）

| 项 | 状态 |
|---|---|
| `MARKETING_VERSION` = 1.2 | ✅ |
| `CURRENT_PROJECT_VERSION` = 3 | ✅ |
| `CFBundleDisplayName` = `Kage Loop`（主屏图标名） | ✅ |
| App 内标题、锁屏播放信息改为 `Kage Loop` | ✅ |
| 官网三个页面改名 + 文案对齐 1.2 | ✅（还需你执行部署脚本，见 A-2） |
| 5 张截图按 1.2 重拍 | ✅ |
| Debug / Release 双配置构建通过 | ✅ |

**A-1｜合并代码**：分支 `release/1.2-kage-loop` → PR → merge 到 `master`。

**A-2｜部署官网**（一条命令，1 分钟）：

```bash
./scripts/deploy-site.sh
```

跑完后打开这三个网址确认显示的是 **Kage Loop**：

- <https://shadowplayer.liuyang19900520.com/>
- <https://shadowplayer.liuyang19900520.com/privacy.html>
- <https://shadowplayer.liuyang19900520.com/support.html>

> 域名 `shadowplayer.liuyang19900520.com` **保持不变**。它已经填在 1.1 的隐私政策/支持网址里，
> 换域名等于让审核员点到一个新地址，没有必要。域名和 App 名不一致不影响审核。

---

### 阶段 B — Xcode 打包上传（你本人，约 20 分钟）

1. 拉取最新 `master`
2. Xcode 顶部设备选 **Any iOS Device (arm64)**（选模拟器会导致 Archive 菜单变灰）
3. **Product → Archive**
4. Organizer 打开后 → 选中刚生成的归档 → **Distribute App**
5. 选 **App Store Connect** → **Upload** → 一路 Next（签名选 Automatically manage signing）
6. 上传成功后等 10–30 分钟，收到「构建版本已完成处理」邮件

> 加密合规问题不会再弹出：`ITSAppUsesNonExemptEncryption = false` 已经写进 Info.plist。

**验证点**：上传前在 Organizer 里确认归档显示 **Version 1.2 (3)**。若显示 1.1 或 build 2，
说明拉的不是最新 master。

---

### 阶段 C — App Store Connect 改名（你本人，约 5 分钟）

> ⚠️ 改名只能在**版本处于「准备提交」状态**时进行。如果当前没有待提交版本，
> 先点左侧的 **＋（版本或平台）** 新建 1.2 版本，改名入口才可编辑。

1. 进入 App → 左侧 **App 信息（App Information）**
2. **名称** 改为 `Kage Loop`
3. **副标题** 改为 `A-B repeat for shadowing`
4. 左上角语言下拉切到 **日本語**，副标题填 `シャドーイング用 A-B リピート`（名称同样填 `Kage Loop`）
5. 再切到 **简体中文**，副标题填 `极简 A-B 循环跟读播放器`
6. 存储（Save）

> **Bundle ID 不要动**，仍是 `com.liuyang19900520.shadowplayer`。改名不影响已安装用户，
> 他们更新后主屏图标名会自动变成 Kage Loop，数据全部保留。

---

### 阶段 D — 填写 1.2 版本信息（你本人，约 15 分钟）

在左侧 **1.2 准备提交** 页面：

| 区块 | 填什么 | 来源 |
|---|---|---|
| 此版本的新增内容 | 三种语言各填一份 | 本文档第 1 节「本次更新说明」 |
| 预览与截屏 | **先删光旧图**，再传 `screenshots/6.9-inch/` 的 5 张，按 01→05 排序 | 第 7 节 |
| 描述 | 三种语言各更新一次 | 第 3.2 / 3.3 节 |
| 关键词 | `kage,loop,repeat,shadowing,language,practice,player,video,AB,study,listening,speaking` | 第 3.4 节 |
| 构建版本 | 点「构建版本」右侧的 **＋**，选 1.2 (3) | — |
| App 审核信息 → 备注 | 复制第 1 节的「审核备注」 | — |

> ⚠️ **「此版本的新增内容」是按语言必填的**。1.1 时就是漏了日语那栏才报红。
> 语言下拉在页面左上角，**English / 日本語 / 简体中文 三栏都要填**。

---

### 阶段 E — 提交前的两道拦路问题（你本人，各 2 分钟）

这两项不填，「提交以供审核」按钮点不下去：

**E-1｜欧盟交易者状态（DSA / Digital Services Act）**

位置：App Store Connect → 右上角账号名 → **业务（Business）** → **交易者状态**
（或提交时会直接弹出）。

- 你是个人开发者、免费 App、不做商业销售 → 选 **「我不是交易者」（I am not a trader）**
- 选了非交易者后，App 在欧盟地区仍可正常上架

**E-2｜年龄分级问卷里的新问题**

位置：1.2 版本页 → **年龄分级** → 编辑。Apple 2025 年新增了几道题，老版本填过也要重答：

| 问题 | 你的答案 |
|---|---|
| App 内是否有社交功能 / 用户间通信？ | **否** |
| 是否有用户生成内容且可被他人看到？ | **否**（单词表只存在本机，不共享） |
| 是否有不受限的网页访问？ | **否** |
| 是否包含广告？ | **否** |
| 是否有 App 内购买/抽奖机制？ | **否** |

全否 → 分级仍是 **4+**。

---

### 阶段 F — 提交与等待

1. 页面右上角 **添加以供审核 / 提交以供审核**
2. 导出合规问题：如果仍然弹出，选 **否**（不使用加密）
3. 状态变为 **等待审核（Waiting for Review）**
4. 预计 24–48 小时出结果

> **改名版本的审核风险点**：审核员会核对截图、描述、App 内显示的名称是否一致。
> 这三处我都已经统一成 Kage Loop，所以风险很低。
> 唯一可能被问的是「为什么改名」——审核备注里已经写明了 previously "A-B Looper ShadowPlayer"。

---

### 通过之后

- App Store 上的名称会在几小时内更新为 **Kage Loop**（搜索索引可能要 1–2 天才跟上）
- 已安装用户更新后，主屏图标名自动变为 Kage Loop，播放列表 / 单词表 / 进度全部保留
- 旧链接（App Store 页面 URL）**不变**，因为 App ID 没变

---

## 10. 1.2 待办清单（打勾用）

```
[ ] A-1  merge release/1.2-kage-loop 到 master
[ ] A-2  ./scripts/deploy-site.sh，三个网址确认显示 Kage Loop
[ ] B    Xcode Archive → Upload，Organizer 显示 1.2 (3)
[ ] C    App Store Connect 改名 + 三语副标题
[ ] D-1  删光旧截图，传 5 张新图
[ ] D-2  三种语言的「此版本的新增内容」
[ ] D-3  三种语言的描述 + 关键词
[ ] D-4  选构建版本 1.2 (3)
[ ] D-5  审核备注
[ ] E-1  欧盟交易者状态 → 我不是交易者
[ ] E-2  年龄分级问卷（全否，4+）
[ ] F    提交以供审核
```

---

## 11. 真机自测清单（提交前跑一遍，约 10 分钟）

模拟器验证不了的几项，建议在你自己的 iPhone 上确认：

| 项 | 怎么测 | 预期 |
|---|---|---|
| 翻译质量 | 单词表打开释义，加几个真实日语词 | 中文释义合理；首次可能提示下载语言包 |
| 进度条手感 | 反复拖动进度条 | 拖动时圆点隐藏，时间读数跟手变色，不错位 |
| 剧集排序 | 相册里放几个 `01_xxx` `02_xxx` `10_xxx` 的视频 | 02 排在 10 前面 |
| 视频删除后 | 从相册删掉一个已加入播放列表的视频 | 该视频留在原播放列表，标注 "Not on this iPhone"，单词表仍可打开 |
| 锁屏信息 | 播放中锁屏 | 控制中心显示 **Kage Loop** |
| 主屏图标名 | 装完看桌面 | **Kage Loop** |

---

## 12. 还没做的（1.3 及以后）

| 功能 | 你提过的诉求 | 状态 |
|---|---|---|
| 单词表导出 CSV | 「至少可以导出 csv」，本机、不联网 | 未开始 |
| 每个单词记时间点，点击跳转 | 「我需要场景来记忆单词」 | 未开始 |
| 单词对应的画面截图 | 同上，可选 | 未开始 |
| CI/CD | 已有计划，等你开口 | 未开始 |
