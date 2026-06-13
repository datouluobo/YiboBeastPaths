# 潘达利亚隐藏猎人宠物资料核对与备用图索引

## 说明

- 本文档用于核对仓库内 10 只潘达利亚隐藏猎人宠物的名称、地图、外观与备用图素材。
- `Data.lua` 里的 `petID` 与当前公开资料中常见的 `NPC ID` 并不完全一致；后续查外部资料时应优先按英文名和本文记录的 `NPC ID` 对照。
- 中文名来源分三类：
  - `Wowhead CN/TW`：能直接检到的当前中文页面标题，优先视为可验证译名。
  - `17173`：熊猫人之谜时期中文攻略里的常用旧译名。
  - `NGA`：仅在缺少可直接访问的 CN 页时作为补充参考。

## 总表

| 仓库 routeID | 当前 NPC ID | 英文名 | 可验证中文名 / 常见旧译 | 仓库现名 | 类型 / 外观 | 地图 | 颜色 / 皮肤 | 备注 |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| 50821 | 50850 | Savage | `萨维奇`（Wowhead CN）；旧译 `野蛮`（17173） | 萨维奇 | 白虎 / 老虎 | 翡翠林 / The Jade Forest | 1 | 独特无瞳亮蓝眼白虎皮肤。 |
| 50822 | 50859 | Glimmer | `微光之蛾`（Wowhead CN）；旧译 `星光`（17173） | 微光之蛾 | 水黾 / Water Strider | 翡翠林 / The Jade Forest | 1 | 你整理的“闪光”不是当前主流可检译名。 |
| 50817 | 50854 | Bloodtooth | `血牙`（17173，且与仓库现名一致） | 血牙 | 龙龟 / Turtle | 卡桑琅丛林 / Krasarang Wilds | 1 | 红色带刺龙龟；Petopia 明确写明南部海岸潜行巡逻。 |
| 66522 | 67820 | Bombyx | `邦比克斯`（Wowhead TW 可检）；`邦比`（仓库现名）；NGA 讨论提到国服可能叫 `桑蚕` | 邦比 | 蚕虫 / Worm | 卡桑琅河，卡桑琅丛林 / Krasarang River, Krasarang Wilds | 1 | 你整理的“蚕虫”更像描述而非稳定译名；这是 10 只里中文名最不稳定的一只。 |
| 50812 | 50885 | Patrannache | `帕特兰纳克`（Wowhead CN）；旧译 `波澜若澈`（17173） | 帕特兰纳克 | 鹤 / Waterfowl | 四风谷 / Valley of the Four Winds | 1 | 粉色鹤，巡逻路线很长。 |
| 50818 | 50960 | Hexapos | `赫克萨波斯`（Wowhead CN）；旧译 `六爪`（17173） | 赫克萨波斯 | 水黾 / Water Strider | 恐惧废土 / Dread Wastes | 1 | 绿底白纹水黾；Petopia 标注为特殊追踪驯服。 |
| 50820 | 51013 | Rockhide the Immovable | `不可撼动的洛克海德`（Wowhead CN） | 洛克海德 | 蜥蜴 / Basilisk | 螳螂高原 / Townlong Steppes | 1 | 石灰灰紫色晶背蜥蜴；你整理的“坚皮”不是当前可检主流译名。 |
| 50813 | 50843 | Portent | `噩兆`（Wowhead CN）；旧译 `天兆`（17173） | 噩兆 | 魁麟 / Quilen | 锦绣谷 / Vale of Eternal Blossoms | 4 | 唯一会在刷新时随机抽取 4 种颜色的稀有：翡翠、紫晶、钴蓝、碧玉/红铜系。 |
| 50816 | 50944 | Bristlespine | `刺脊`（Wowhead CN/TW 检索与仓库现名一致） | 刺脊 | 豪猪 / Rodent | 昆莱山 / Kun-Lai Summit | 1 | 紫黑色豪猪；你整理的“芒刺”不是当前主流可检译名。 |
| 50811 | 50998 | Stompy | `重蹄`（Wowhead CN） | 重蹄 | 羊 / Gruffhorn | 昆莱山 / Kun-Lai Summit | 1 | Petopia 家族名是 `Gruffhorn`；外观上就是白灰色山羊/牦牛羊系模型。 |

## 备用图文件

目录：`Assets/ReferencePets/PandariaHiddenHunterPets`

| 宠物 | 文件 |
| --- | --- |
| Savage | `50850_savage.jpg` |
| Glimmer | `50859_glimmer.jpg` |
| Bloodtooth | `50854_bloodtooth.jpg` |
| Bombyx | `67820_bombyx.jpg` |
| Patrannache | `50885_patrannache.jpg` |
| Hexapos | `50960_hexapos.jpg` |
| Rockhide the Immovable | `51013_rockhide_the_immovable.jpg` |
| Portent | `50843_portent_jade.jpg` |
| Portent | `50843_portent_amethyst.jpg` |
| Portent | `50843_portent_cobalt.jpg` |
| Portent | `50843_portent_jasper.jpg` |
| Bristlespine | `50944_bristlespine.jpg` |
| Stompy | `50998_stompy.jpg` |

## 建议后续命名

- 如果你后面要把资料继续喂给路线脚本、截图脚本或素材整理脚本，建议统一按 `英文名 + 当前 NPC ID` 管理外部素材。
- 仓库里已有的 `routeID` 建议继续保留，不要直接替换；但文档、图片、后续新脚本最好都附带一列 `当前 NPC ID`。
- `Bombyx` 建议后续在你能访问国服客户端或游戏内工具提示时，再补一次最终中文定名。

## 来源

- Petopia NPC 页面：
  - `https://www.wow-petopia.com/npc.php?id=50850`
  - `https://www.wow-petopia.com/npc.php?id=50859`
  - `https://www.wow-petopia.com/npc.php?id=50854`
  - `https://www.wow-petopia.com/npc.php?id=67820`
  - `https://www.wow-petopia.com/npc.php?id=50885`
  - `https://www.wow-petopia.com/npc.php?id=50960`
  - `https://www.wow-petopia.com/npc.php?id=51013`
  - `https://www.wow-petopia.com/npc.php?id=50843`
  - `https://www.wow-petopia.com/npc.php?id=50944`
  - `https://www.wow-petopia.com/npc.php?id=50998`
- 17173《熊猫人之谜》隐藏猎人宠物整理：
  - `https://wow.17173.com/content/2012-08-04/20120804142336581_1.shtml`
  - `https://wow.17173.com/content/2012-08-04/20120804142336581_2.shtml`
  - `https://wow.17173.com/content/2012-08-04/20120804142336581_3.shtml`
- Wowhead CN/TW 命名检索入口：
  - `https://www.wowhead.com/cn/npc=50850`
  - `https://www.wowhead.com/cn/npc=50859`
  - `https://www.wowhead.com/cn/npc=50885`
  - `https://www.wowhead.com/cn/npc=50960`
  - `https://www.wowhead.com/cn/npc=51013`
  - `https://www.wowhead.com/cn/npc=50843`
  - `https://www.wowhead.com/cn/npc=50998`
  - `https://www.wowhead.com/tw/npc=67820`
  - `https://www.wowhead.com/tw/npc=50944`
