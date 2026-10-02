# App Store 截图

由 iPhone 17 Pro Max 模拟器（Release 构建，1.2 / build 3）截取，状态栏已统一为 Apple 规范的 9:41 样式。

## 6.9 吋（1320 × 2868）

App Store Connect 目前只强制要求这一组，其余尺寸会自动缩放。

| 文件 | 内容 | 上传顺序 |
|---|---|---|
| `01-player-ab.png` | **播放页：A-B 循环激活**——进度条上有 A/B 标记与循环区间，Set A / Set B 高亮，下方是带释义的单词表 | 1（主图） |
| `02-home.png` | 首页：最近播放（显示所属播放列表）+ 播放列表 + 右上角单词表入口 | 2 |
| `03-word-meanings.png` | 单集单词表：日语单词 + 中文释义，设备端翻译 | 3 |
| `04-word-lists.png` | 单词表浏览器：按播放列表 → 按剧集两级 | 4 |
| `05-playlist.png` | 播放列表详情：命名后的剧集按 01/02/03 顺序排列 | 5 |

`01-player-ab.png` 放第一张——它最能体现核心卖点。

## 重新生成

1. 素材视频用 ffmpeg 生成（模拟日语课程画面）。
   生成时文字里**不要包含撇号**（`'`），否则会破坏 ffmpeg 的 drawtext 转义并把滤镜字符串渲染进画面。
2. 导入模拟器相册：`xcrun simctl addmedia <sim> lesson.mp4`
3. 装 Release 构建并设置状态栏：
   ```bash
   xcrun simctl status_bar <sim> override --time "9:41" --wifiMode active --wifiBars 3 \
     --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
   ```
4. 需要预置剧集名 / 单词表时，**先关机再改 plist**：
   模拟器运行时 `cfprefsd` 会把缓存里的旧值刷回去，直接 `defaults write` 会被覆盖。
   ```bash
   xcrun simctl shutdown <sim>
   # 编辑 .../Data/Application/<uuid>/Library/Preferences/com.liuyang19900520.shadowplayer.plist
   xcrun simctl boot <sim>
   ```
5. 播放页的控件 3 秒后自动隐藏：点一下画面后**连拍多张**，取控件还在的那张。
