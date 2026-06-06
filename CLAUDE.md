# FreeFight - AI 协作指南

<!-- AI-CONTEXT: 本文件是 AI 助手进入本项目时的首要入口。请完整阅读后再开始工作。 -->

## 项目概述

FreeFight 是一个 **Godot 4.6 单机线框 Demo**，核心玩法为房间制地下城 + 实时战斗 + 策略部署 + 共鸣演化。**玩家唯一操作 = 从 3 张候选中选 1 张拖到事件格子上**；其余 2 张自动弃掉。怪物固定在部署格子上不动，英雄沿 A* 最短路径逐格走向最近怪物。击杀怪物后英雄站到该格子触发格子效果。玩家通过"在哪个事件格放怪物"决定获得哪些增益。一局 = 树状房间地图，清除房间内所有事件后出口开启，探索到 Boss 房间击杀 Boss。

**关键词**：实时战斗、3 选 1 候选、房间制地图、A* 寻路、事件格部署、击杀触发效果、英雄逐格移动、怪物固定、共鸣被动技能、模式识别 Combo、精英变体、无回合 / 无主动技能

## 必读文档

在修改代码前，请阅读以下文档：

| 优先级 | 文档 | 作用 |
|--------|------|------|
| **必读** | [docs/rules/development-scope.md](docs/rules/development-scope.md) | 开发边界与禁止事项 |
| **必读** | [docs/knowledge/v7-房间制地下城设计.md](docs/knowledge/v7-房间制地下城设计.md) | **v7 现行设计** |
| 参考 | [docs/knowledge/README.md](docs/knowledge/README.md) | 文档索引 |
| 归档 | docs/archive/ | 历史版本设计（v6 及更早） |

## 核心规则（摘要）

> 完整规则见 `docs/rules/development-scope.md`

1. **实时制**：本项目没有回合、轮次、turn 概念
2. **玩家唯一操作 = 部署**：除了"3 选 1 + 部署位置"，玩家不做任何其他操作（无主动技能、无弃牌按钮、无装备穿卸、无抉择弹窗）
3. **无装备 / 无持仓 debuff**
4. **无自动刷怪**：怪物只能由玩家拖拽部署产生（Boss 召唤除外）
5. **事件格部署**：拖拽到未清除的事件格上，格子大小 64×64 像素
6. **最小改动**：只改与任务直接相关的文件，不顺手重构
7. **先问再做**：需求含糊或超出允许范围时，先向用户确认
8. **线框 Demo 定位**：UI 用 ColorRect / Panel / Label

## 架构速查

```
引擎: Godot 4.6 | 语言: GDScript
入口: res://scenes/main_menu.tscn

Autoload:
  - GameManager    (跨场景状态 + 怪物图鉴)
  - DataRegistry   (扫描 resources/monsters & evolutions)
  - RunManager     (Run 状态 + 击杀属性自动累计 + 深度难度缩放)

数据层: Resource (.tres) + RefCounted (静态定义)
  - CombatStats / MonsterData / BuffDef / BuffInstance
  - EvolutionPath / CardPool / HybridEvolution / BossData
  - DungeonTileType (格子类型枚举: 15 种)

战斗核心 (v7 房间制):
  - DungeonBattleController: 主控制器 + 房间管理
  - WorldMap: 树状房间地图数据
  - DungeonGrid: 10×8 单房间格子数据 (墙壁/空地/事件格/出口)
  - MapGenerator: 生成树状房间拓扑 + 每房间布局
  - GridPathfinder: AStar2D 寻路
  - DungeonRenderer: 格子渲染 + 事件高亮 + 出口状态
  - DungeonCamera: 跟随英雄 + 拖拽 + 缩放
  - TileEffectSystem: 格子效果触发 (击杀后) + 连锁倍率 + 怪物-格子亲和
  - GridDropZone: 事件格部署 + 路径预览 + 亲和匹配提示
  - PathPreview: 拖拽时显示预计路径
  - MiniMap: 右上角房间树状地图

  - CombatUnit (薄基类)
    → Hero (格子移动: A* 逐格走, 0.3s/步, 击杀后触发目标格效果)
    → Monster (固定不动, 含 7 种独特机制)
  - 候选: 3 张固定，部署后 2s CD，CD 结束后刷新（CardHand）
  - ComboTracker: 模式识别（生态专精 / 异种联动 / 密集部署）
  - EvolutionTracker: 共鸣进度 → 21 个被动 + 8 混合机制
  - FriendlySkeleton / UndeadAura: 友方召唤物

怪物机制:
  史莱姆死亡分裂(相邻空格) / 蝙蝠飞行 / 狼群族加速 / 哥布林死亡爆炸
  骷髅墓碑复活 / 石像鬼永久防御光环 / 毒蛇死亡变毒沼格

事件格类型 (击杀怪物后触发, 数值按连锁×亲和倍率缩放):
  正面: 治愈泉(+10HP) / 力量祭坛(攻+2) / 铁壁祭坛(防+2) / 共鸣水晶(×2) / 宝箱(永久属性+1)
  负面: 毒沼(-8HP+毒涂层) / 陷阱(-12HP+攻速) / 诅咒地(攻-2+共鸣×2) / 减速泥(减速+防御)
  随机: 问号格(从事件池抽取)

连锁倍率: 房间内每清除一个事件+1, 效果 = 基础值 × (1 + 连锁 × 0.3)
怪物-格子亲和: 猛攻(狼/哥布林/螳螂↔力量祭坛/陷阱) / 坚韧(骷髅/石像鬼↔铁壁/减速泥)
  灵巧(蝙蝠/毒蛇/萤火虫↔共鸣/诅咒/问号) / 生命(史莱姆/树人↔治愈泉/毒沼/宝箱)
  匹配时效果 ×1.5
  特殊: 出口(清除所有事件后开启) / Boss门(触发Boss)

英雄基础: 150 HP / 10 攻 / 3 防 / 1.0 攻速 / 48 近战射程
部署 CD: 2.0s | 手牌候选: 3 张 | 精英概率: 10% | Combo 窗口: 4s
地图: 树状 6-9 房间 | 每房间 10×8 格子 | 无迷雾
房间类型: 起始/普通/宝藏/危险/精英/Boss
难度: 深度0-1×1.0 / 2-3×1.3 / 4-5×1.6 / 6+×2.0 / Boss×2.5
伤害公式: max(1, atk - max(0, def - armor_penetration))
```

## 目录结构

```
res://
├── autoload/          # Autoload 单例（GameManager / DataRegistry / RunManager）
├── data/              # Resource 类定义 + DungeonTileType 枚举
├── resources/         # 怪物 / 共鸣 / 卡池 .tres
├── scenes/            # 场景（主菜单 / 图鉴 / 战斗）
│   └── battle/        # dungeon_battle_scene.tscn (v6 主场景)
├── scripts/
│   ├── battle/        # 战斗核心 + 地下城系统
│   └── ui/
├── assets/            # 简单贴图
└── docs/              # 项目文档（10-v6 为现行设计）
    ├── knowledge/     # 技术文档
    ├── plans/         # 开发计划归档
    └── rules/         # 开发规则
```
