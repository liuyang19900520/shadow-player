# App Store 截图

由 iPhone 17 Pro Max 模拟器（Release 构建）截取，状态栏已统一为 Apple 规范的 9:41 样式。

## 6.9 吋（1320 × 2868）

App Store Connect 目前只强制要求这一组，其余尺寸会自动缩放。

| 文件 | 内容 | 建议顺序 |
|---|---|---|
| `01-home.png` | 首页：最近播放 + 播放列表 | 2 |
| `02-player-ab.png` | **播放页：A-B 循环激活**（进度条上有 A/B 标记和循环区间）+ 单词表 | **1（主图）** |
| `03-wordlist-ab.png` | 单词表编辑 + A/B 按钮激活态 | 3 |
| `04-playlist.png` | 播放列表详情 + Combined Word List 入口 | 4 |
| `05-combined-words.png` | 合并单词表（汇总列表内所有视频的词） | 5 |

建议把 `02-player-ab.png` 放第一张——它最能体现核心卖点。

## 重新生成

素材视频用 ffmpeg 生成（模拟日语课程画面），导入模拟器相册后手动走一遍流程截取。
注意：生成时文字里**不要包含撇号**（`'`），否则会破坏 ffmpeg 的 drawtext 转义并把滤镜字符串渲染进画面。
