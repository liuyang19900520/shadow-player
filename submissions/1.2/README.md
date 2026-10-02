# 1.2 —— 改名为 Kage Loop（已发布）

| 项 | 值 |
|---|---|
| 版本 / 构建号 | 1.2 (3) |
| 提交 | 2026-09-28 |
| 状态 | ✅ **已发布** 2026-09-28 |
| 商店名 | `A-B Looper ShadowPlayer` → **`Kage Loop`** |

## 本次改动

- App 改名为 Kage Loop（商店名、桌面图标名、App 内标题、锁屏播放信息、权限说明）
- 视频和播放列表可以命名；剧集按名称中的数字排序（02 排在 10 前面）
- 首页新增单词表入口：按播放列表 → 剧集两级浏览；视频删除后单词表保留
- 最近播放显示所属播放列表，数量 3 → 4
- 移除 Combined Word List
- 修复：拖动进度条时圆点错位；点击 Done 有时不翻译

## 文件

| 文件 | App Store Connect 字段 |
|---|---|
| `en/` `ja/` `zh-Hans/` → `subtitle.txt` | App 信息 → 副标题 |
| `en/` `ja/` `zh-Hans/` → `whats-new.txt` | 此版本的新增内容 |
| `en/` `zh-Hans/` → `description.txt` | 描述（日语描述当时未存档） |
| `en/keywords.txt` | 关键词（英语） |
| `en/promotional-text.txt` | 促销文本（英语） |
| `review-notes.txt` | App 审核信息 → 备注 |
| `screenshots/6.9-inch/` | 预览和截屏（5 张） |

---

## 当时的提交步骤（存档）

### 9. 提交 1.2（改名版）的完整步骤

> 顺序很重要：**先改名，再传构建包**。名称是 App 级别的，构建包是版本级别的，
> 但同一次「提交审核」会把两者一起送审——改名和新版本必须在同一次提交里。

#### 阶段 A — 我已经做完的（无需你操作）

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

#### 阶段 B — Xcode 打包上传（你本人，约 20 分钟）

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

#### 阶段 C — App Store Connect 改名（你本人，约 5 分钟）

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

#### 阶段 D — 填写 1.2 版本信息（你本人，约 15 分钟）

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

#### 阶段 E — 提交前的两道拦路问题（你本人，各 2 分钟）

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

#### 阶段 F — 提交与等待

1. 页面右上角 **添加以供审核 / 提交以供审核**
2. 导出合规问题：如果仍然弹出，选 **否**（不使用加密）
3. 状态变为 **等待审核（Waiting for Review）**
4. 预计 24–48 小时出结果

> **改名版本的审核风险点**：审核员会核对截图、描述、App 内显示的名称是否一致。
> 这三处我都已经统一成 Kage Loop，所以风险很低。
> 唯一可能被问的是「为什么改名」——审核备注里已经写明了 previously "A-B Looper ShadowPlayer"。

---

#### 通过之后

- App Store 上的名称会在几小时内更新为 **Kage Loop**（搜索索引可能要 1–2 天才跟上）
- 已安装用户更新后，主屏图标名自动变为 Kage Loop，播放列表 / 单词表 / 进度全部保留
- 旧链接（App Store 页面 URL）**不变**，因为 App ID 没变

---

### 10. 1.2 待办清单（打勾用）

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

### 11. 真机自测清单（提交前跑一遍，约 10 分钟）

模拟器验证不了的几项，建议在你自己的 iPhone 上确认：

| 项 | 怎么测 | 预期 |
|---|---|---|
| 翻译质量 | 单词表打开释义，加几个真实日语词 | 中文释义合理；首次可能提示下载语言包 |
| 进度条手感 | 反复拖动进度条 | 拖动时圆点隐藏，时间读数跟手变色，不错位 |
| 剧集排序 | 相册里放几个 `01_xxx` `02_xxx` `10_xxx` 的视频 | 02 排在 10 前面 |
| 视频删除后 | 从相册删掉一个已加入播放列表的视频 | 该视频留在原播放列表，标注 "Not on this iPhone"，单词表仍可打开 |
| 锁屏信息 | 播放中锁屏 | 控制中心显示 **Kage Loop** |
| 主屏图标名 | 装完看桌面 | **Kage Loop** |
