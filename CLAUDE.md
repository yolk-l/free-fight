# FreeFight - AI 协作指南

<!-- AI-CONTEXT: 本文件是 AI 助手进入本项目时的首要入口。请完整阅读后再开始工作。 -->

## 项目概述

FreeFight 是一个 **Godot 4.6 单机线框 Demo**，核心玩法为地下城格子探索 + 实时战斗 + 策略部署 + 共鸣演化。**玩家唯一操作 = 从 3 张候选中选 1 张拖到格子上**；其余 2 张自动弃掉。怪物固定在部署格子上不动，英雄沿 A* 最短路径逐格走向最近怪物，经过的每个格子触发效果（加血/陷阱/随机事件等）。玩家通过"在哪个格子放怪物"间接规划英雄行走路线。一局 = 1 张大地图探索到 Boss 房间击杀 Boss。

**关键词**：实时战斗、3 选 1 候选、格子地图、A* 寻路、迷雾探索、格子效果、英雄逐格移动、怪物固定、共鸣被动技能、模式识别 Combo、精英变体、无回合 / 无主动技能

## 必读文档

在修改代码前，请阅读以下文档：

| 优先级 | 文档 | 作用 |
|--------|------|------|
| **必读** | [docs/rules/development-scope.md](docs/rules/development-scope.md) | 开发边界与禁止事项 |
| **必读** | [docs/knowledge/10-v6-地下城探索设计.md](docs/knowledge/10-v6-地下城探索设计.md) | **v6 设计定稿**（唯一事实来源）|
| 参考 | [docs/knowledge/README.md](docs/knowledge/README.md) | 文档索引 |
| 归档 | docs/knowledge/06-09-*.md | v2~v5 历史，已被 v6 取代 |

## 核心规则（摘要）

> 完整规则见 `docs/rules/development-scope.md`

1. **实时制**：本项目没有回合、轮次、turn 概念
2. **玩家唯一操作 = 部署**：除了"3 选 1 + 部署位置"，玩家不做任何其他操作（无主动技能、无弃牌按钮、无装备穿卸、无抉择弹窗）
3. **无装备 / 无持仓 debuff**
4. **无自动刷怪**：怪物只能由玩家拖拽部署产生（Boss 召唤除外）
5. **格子部署**：拖拽到已探索的空格子上，格子大小 64×64 像素
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
  - RunManager     (Run 状态 + 击杀属性自动累计 + 距离难度缩放)

数据层: Resource (.tres) + RefCounted (静态定义)
  - CombatStats / MonsterData / BuffDef / BuffInstance
  - EvolutionPath / CardPool / HybridEvolution / BossData
  - DungeonTileType (格子类型枚举: 14 种)

战斗核心 (v6 地下城):
  - DungeonBattleController: 主控制器
  - DungeonGrid: 30×20 格子数据 (墙壁/空地/效果格)
  - MapGenerator: 随机房间 + 走廊 + 格子效果分配
  - GridPathfinder: AStar2D 寻路
  - DungeonRenderer: 格子渲染 + 迷雾
  - DungeonCamera: 跟随英雄 + 拖拽 + 缩放
  - TileEffectSystem: 格子效果触发 (14 种)
  - GridDropZone: 格子部署 + 路径预览
  - PathPreview: 拖拽时显示预计路径
  - MiniMap: 右上角小地图

  - CombatUnit (薄基类)
    → Hero (格子移动: A* 逐格走, 0.3s/步, 经过格子触发效果)
    → Monster (固定不动, 含 7 种独特机制)
  - 候选: 3 张固定，部署后 2s CD，CD 结束后刷新（CardHand）
  - ComboTracker: 模式识别（生态专精 / 异种联动 / 密集部署）
  - EvolutionTracker: 共鸣进度 → 21 个被动 + 8 混合机制
  - FriendlySkeleton / UndeadAura: 友方召唤物

怪物机制:
  史莱姆死亡分裂(相邻空格) / 蝙蝠飞行 / 狼群族加速 / 哥布林死亡爆炸
  骷髅墓碑复活 / 石像鬼永久防御光环 / 毒蛇死亡变毒沼格

格子类型:
  正面: 治愈泉(+10HP) / 力量祭坛(攻+2) / 铁壁祭坛(防+2) / 共鸣水晶(×2) / 宝箱(永久属性+1)
  负面: 毒沼(-8HP) / 陷阱(-12HP) / 诅咒地(攻-2) / 减速泥(移速减半)
  随机: 问号格(从事件池抽取)
  特殊: 视野塔(揭6格) / 传送阵(传送配对) / Boss门(触发Boss)

英雄基础: 150 HP / 10 攻 / 3 防 / 1.0 攻速 / 48 近战射程
部署 CD: 2.0s | 手牌候选: 3 张 | 精英概率: 10% | Combo 窗口: 4s
地图: 30×20 格子 | 房间 4-6 个 | 迷雾 | 视野半径 3 格
难度: 0-10格×1.0 / 11-20格×1.3 / 21-30格×1.6 / 31+格×2.0 / Boss×2.5
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
