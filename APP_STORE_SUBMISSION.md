# Kage Loop — App Store 通用参考

> **每个版本的文案、截图和提交步骤都在 [submissions/](submissions/) 里，一个版本一个文件夹。**
> 这份文档只放各版本都一样、很少变动的信息。

---

## 1. App 基本信息

| 字段 | 内容 |
|---|---|
| App 名称 | `Kage Loop`（1.2 起；1.0–1.1 为 `A-B Looper ShadowPlayer`） |
| Apple ID | `6806611473` |
| Bundle ID | `com.liuyang19900520.shadowplayer` |
| SKU | `shadowplayer-001` |
| 主要语言 | English (U.S.)；另有 日本語、简体中文 |
| 主类别 / 次类别 | Education / Photo & Video |
| 年龄分级 | 4+ |
| 价格 | Free，全部地区 |
| 设备 | 仅 iPhone |
| 开发者名称 | Yang LIU（个人账号显示法定姓名；大小写只能联系 Apple 开发者支持修改） |

> 仓库、Xcode target、`ShadowPlayerApp` 类型名、Bundle ID 和官网域名都保留 shadowplayer，这是有意的，不要改。

---

## 2. 网站

| 用途 | 网址 |
|---|---|
| 隐私政策（必填） | `https://shadowplayer.liuyang19900520.com/privacy.html` |
| 支持网址（必填） | `https://shadowplayer.liuyang19900520.com/support.html` |
| 营销网址（选填） | `https://shadowplayer.liuyang19900520.com/` |

源文件在 `docs/`，改完后执行：

```bash
./scripts/deploy-site.sh
```

脚本会同步到 S3 并清除 CloudFront 缓存。执行完终端停在 `(END)` 时按 `q` 退出即可，那是 AWS CLI 的分页器。

### AWS 资源（账号 `324971275476`）

| 资源 | 标识 |
|---|---|
| S3 桶（私有） | `shadowplayer.liuyang19900520.com` |
| ACM 证书（us-east-1） | `075d8827-89d0-4baa-95f3-e0393e20b030` |
| CloudFront 分发 | `EOJATFWF8U3SJ` → `d2kw8li0le4l0e.cloudfront.net` |
| Origin Access Control | `ECNMRWOH6D14Y` |
| Route53 A 记录（别名） | `shadowplayer.liuyang19900520.com` |

S3 保持私有，只允许这个 CloudFront 分发通过 OAC 读取；HTTP 301 跳转到 HTTPS；TLS 1.2+。费用每月约 $0.5 以内。

---

## 3. App 隐私标签（App Privacy）

**Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app**

商店显示为 **「Data Not Collected」**。依据（被问到时可以这样回复）：

- 没有任何网络请求代码（没有 `URLSession`，没有第三方 SDK）
- 所有数据（最近播放、播放列表、单词表、进度、设置）只用 `UserDefaults` 存在设备上
- 相册权限只用来读取用户选择的视频，不复制、不上传
- 单词释义用 Apple 设备端翻译（iOS 18+），在设备上完成
- 摇一摇录入用 Apple 设备端语音识别（iOS 26+），在设备上完成
- 首次使用某种语言时，iOS 可能下载 Apple 的翻译或语音模型。这是系统自己的下载，App 不发送任何数据

> 以后如果加了任何会联网或收集数据的功能，这一节和隐私政策都必须先改。

---

## 4. 导出合规

`ShadowPlayer-Info.plist` 里已经有 `ITSAppUsesNonExemptEncryption = false`，上传时不会再问加密问题。
万一被问到，选 **No**：App 只用系统标准 API，没有自定义加密。

---

## 5. 和审核有关的工程设置

| 设置 | 作用 |
|---|---|
| `ShadowPlayer/PrivacyInfo.xcprivacy` | 声明 `UserDefaults` 的 Required Reason API（`CA92.1`）。没有它上传会被自动拒 |
| `TARGETED_DEVICE_FAMILY = 1` | 仅 iPhone |
| `NSPhotoLibraryUsageDescription` | 相册权限说明。`PHAccessLevel` 没有只读级别，`.readWrite` 是读取相册的唯一选项 |
| `NSSpeechRecognitionUsageDescription` | 语音识别权限说明（1.3 起）。只有第一次识别失败时才会请求 |
| `ITSAppUsesNonExemptEncryption = false` | 跳过加密合规问题 |
| `CURRENT_PROJECT_VERSION` | **每次上传都必须加 1**（1–4 已用） |

---

## 6. 开发者账号

- 个人账号，Team ID `3T7MJA53W9`。从免费账号升级时 Apple 是原地升级，Team ID 没变
- 会员每年 $99，签名有效期 1 年
- Xcode → Settings → Accounts 用 `liuyang19900520@gmail.com` 登录

---

## 7. 通用打包上传流程

1. 拉取最新 `master`，确认 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 已更新
2. 顶部设备选 **Any iOS Device (arm64)**（选模拟器的话 Archive 是灰的）
3. **Product → Archive**，在 Organizer 里确认版本号和构建号
4. **Distribute App → App Store Connect → Upload**
5. 等处理完成的邮件（10–30 分钟）
6. 按 `submissions/<版本号>/README.md` 填写 App Store Connect 并提交

预计审核时长 24–48 小时。

---

## 8. 还没做的

| 功能 | 你提过的诉求 | 状态 |
|---|---|---|
| 读画面字幕录入（C 方案）+ A/C 切换设置 | 「后续弄一个设置，可以手动选择 A 或者 C」 | 未开始；文字来源已经做成可替换的一层 |
| 单词表导出 CSV | 「至少可以导出 csv」，本机、不联网 | 未开始 |
| App 单元测试 target | — | 未开始；切句规则在 `Packages/PhraseKit` 里，已有测试 |
| B 点在片尾时循环中断 | — | 已单独开任务 |
| CI/CD | 已有计划，等你开口 | 未开始 |

摇一摇录入（A 方案：设备端语音识别）已在 1.3 完成，见 [submissions/1.3](submissions/1.3/)。
