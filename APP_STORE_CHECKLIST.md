# ShadowPlayer — App Store 上架合规检查清单

> 审视日期：2026-08-27 ｜ 基于当前代码全盘扫描的结果
> 用法：按「阻塞项 → 提交前必办 → 建议项」的顺序处理，勾掉一项划一项。

## 总体结论

**可以上架。** 目前没有发现内容或功能层面的硬性障碍：

- App 播放的是**用户自己相册里的视频**，不分发第三方内容 → 不涉及版权（指南 5.2）
- 功能完整（自定义播放器、A-B 循环、单词表、播放列表）→ 不会被 4.2「最低功能要求」拒
- **零网络请求、零数据收集、无账号、无内购、无广告 SDK** → 隐私与商业条款风险极低

剩下的工作集中在**账号注册**和 **App Store Connect 表单/素材**，不需要大改代码。

---

## 一、阻塞项（不做就传不上去）

### ✅ 1. 隐私清单 PrivacyInfo.xcprivacy — 已完成

- **状态**：已添加 `ShadowPlayer/PrivacyInfo.xcprivacy`，并确认已打包进 .app
- **背景**：App 使用 `UserDefaults` 存储最近播放、播放列表、单词表、播放进度。自 2024 年起这属于 Apple 的 **Required Reason API**，未声明会在**上传阶段被自动校验拒绝**（连人工审核都进不去）
- **声明内容**：类别 `NSPrivacyAccessedAPICategoryUserDefaults`，理由码 `CA92.1`（仅 App 自身读写，不与其他 App 共享）—— 与实际代码一致
- ⚠️ **今后新增第三方库或用到文件时间戳 / 磁盘空间 / 系统启动时间等 API 时，必须回来补充声明**

### ☐ 2. 付费开发者账号 + 重新签名

- 注册 Apple Developer Program（$99/年）
- 注册后在 Xcode → Signing & Capabilities 把 Team 换成新团队（当前是个人免费团队 `3T7MJA53W9`）
- 签名有效期从 **7 天** 变为 **1 年**（免费账号 7 天过期会导致 App 打不开 —— 之前遇到过的黑屏就是这个原因）

### ☐ 3. Bundle ID 确认唯一

- 当前：`com.shadowplayer.app`
- 需在 App Store Connect 注册该 ID。若已被占用，改成带自有域名反写的形式（如 `com.<你的域名>.shadowplayer`）
- ⚠️ **一旦上架就不可更改**，注册前想清楚

---

## 二、提交前必办（App Store Connect 表单与素材）

### ☐ 4. 隐私政策网址（强制）

Apple 要求**所有 App**都提供，哪怕不收集任何数据。

- 可用 GitHub Pages 免费托管一个静态页
- 内容照实写即可：本 App 不收集、不上传、不共享任何用户数据；所有数据（播放记录、播放列表、单词表）仅保存在用户设备本地；仅在用户主动选择视频时访问相册，且从不修改相册内容

### ☐ 5. 支持网址（强制）

提交时必填，可复用上面的页面或直接填 GitHub 仓库地址。

### ☐ 6. App 隐私标签（App Privacy）

在 App Store Connect 中如实勾选 **「不收集数据」（Data Not Collected）**。

- 依据：全项目扫描确认**无任何 `URLSession` / 网络请求代码**，无分析或广告 SDK
- 这是加分项，对审核和用户信任都有利

### ☐ 7. 应用截图

- 需要 **6.7 吋**和 **6.1 吋** iPhone 尺寸的截图（因已设为仅 iPhone，**无需 iPad 截图**）
- 建议展示：首页（播放列表 + 最近播放）、播放页（A-B 循环）、单词表、合并单词表

### ☐ 8. 版本号

- 当前 `MARKETING_VERSION = 1.0`、`CURRENT_PROJECT_VERSION = 1`
- 每次向 App Store Connect 上传构建包，**Build 号必须递增**

### ☐ 9. 导出合规问卷（加密）

- 提交时会询问是否使用加密。本 App 仅使用系统标准 API，**选「否」/ 标准豁免**即可，无需额外提交文件

---

## 三、代码层面：已核查通过的项

| 检查项 | 结果 |
|---|---|
| 隐私清单 | ✅ 已添加并打包 |
| 仅 iPhone | ✅ `TARGETED_DEVICE_FAMILY = 1`，已移除 iPad 方向配置（播放页有按屏宽硬编码的 16:9，iPad 上比例会不对，故不适配） |
| 相册权限用途说明 | ✅ `NSPhotoLibraryUsageDescription` 已填写且具体，说明了「为什么」需要 |
| 相册权限范围 | ✅ 使用 `.readWrite`。注：`PHAccessLevel` 只有 `.addOnly` / `.readWrite` 两级，**没有只读级别**，读取相册只能用 `.readWrite`；App 实际从不修改用户相册 |
| 后台音频权限 | ✅ `UIBackgroundModes = [audio]`，用于锁屏后继续播放，属播放器类 App 的正当用途 |
| App 图标 | ✅ 单张 1024×1024（Xcode 14+ 自动生成各尺寸），无 alpha 通道要求需注意 |
| 启动屏 | ✅ 使用 `UILaunchScreen_Generation`，符合现代要求 |
| 调试残留 | ✅ 无 `TODO` / `FIXME` / `print()` |
| 网络请求 | ✅ 无，因此无需 ATS 例外配置 |
| Release 构建 | ✅ 通过，无错误无警告 |

---

## 四、建议项（不影响过审，但影响体验/评分）

### ☐ 10. 「Sync Word List」按钮当前是占位

点击弹出 "Coming Soon"。审核员可能会点到。

- **风险**：指南 2.1 不喜欢「明显未完成的功能」。单个占位按钮通常不会被拒，但存在被质询的可能
- **建议二选一**：
  - a) **提交前先隐藏这个按钮**，等功能真正做完再随新版本放出（最稳）
  - b) 保留，但把提示文案改得更像「规划中的功能」而非「没做完」
- 未来实现时的最低成本方案：**iCloud Key-Value Store 或 iCloud Documents 存一份 JSON** —— 零服务器、零费用、随 Apple ID 自动同步，无需 DynamoDB

### ☐ 11. App 名称查重

「ShadowPlayer」需在 App Store Connect 查是否已被占用；名称在全球范围内唯一。

### ☐ 12. 权限拒绝后的降级体验

已实现「跳转设置」的提示，符合预期。建议真机上实测一遍「拒绝权限 → 提示 → 跳设置 → 授权后返回」的完整流程。

### ☐ 13. 空状态与首次启动体验

审核员是**全新安装、无任何数据**的状态进入。当前空状态文案已具备（"No videos yet. Tap Select Video above to start."），建议自己用全新模拟器走一遍首次启动流程，确保引导清晰。

### ☐ 14. 音量增益的听感检查

`AudioBoost` 使用 1.8×（≈+5dB）增益。这不是合规问题，但建议确认在音量较大的素材上**不会破音**，避免用户差评。

---

## 五、审核时间预期

- 首次提交通常 **24–48 小时**内有结果
- 若被拒，Resolution Center 会说明原因，改完可直接重新提交，无需等待
- 本 App 风险点少，一次过审概率较高

---

## 附：提交流程速查

1. Xcode 中 Team 切换为付费账号
2. 递增 Build 号
3. Product → Archive（真机 / Any iOS Device）
4. Organizer → Distribute App → App Store Connect
5. 在 App Store Connect 填写元数据、上传截图、完成隐私标签
6. 提交审核
