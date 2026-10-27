# 1.4 —— 每日精读打卡（草稿）

> ⚠️ **草稿**：`feature/daily-checkin` 还没合并进 develop。功能定稿、真机验证后再改文案和审核备注。

| 项 | 值 |
|---|---|
| 版本 | **1.4**（develop 上已 bump，见 PR #19） |
| 商店名 | Kage Loop（不变） |
| 状态 | 📝 草稿 |

## 本次改动（依据 `design/daily-checkin.md` 与 feature/daily-checkin 的提交）

- **每日精读打卡**：英语、日语各 5 分钟/天。A-B 完整循环满 3 遍、5:00–23:00 内完成才计入；按视频时长 B−A 计、与倍速无关；同一天重叠只算一次；语言取播放列表音频语言。只存本机，不同步、不提醒、不补卡
- **首页改版**：Today 卡片 + 本周 7 天、Continue、Recent、Playlists；月历（上半英语/下半日语）、日详情半屏（分钟数、新单词）
- **`+` 菜单**：首页和播放列表页统一用右上角 `+` 添加视频/播放列表
- 单词新增 `createdAt`（旧单词无日期，不计入）

develop 自 1.3 以来其余改动均为 CI（TestFlight 上传、提交审核 workflow）和版本号，不影响用户。

## 待确认

- [ ] 打卡功能完成后，按最终行为核对三种语言的 whats-new.txt 和 review-notes.txt
- [ ] 是否需要更新 description / promotional-text / keywords / 截图（本草稿未包含，提交脚本只读 whats-new.txt 和 review-notes.txt）
- [ ] 审核备注步骤 1 的「+ → 从相册添加」按实际菜单文字修正
- [ ] 隐私政策：打卡数据只存本机，确认无需修改
