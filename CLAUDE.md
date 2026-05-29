# FreeFight - AI 协作指南

<!-- AI-CONTEXT: 本文件是 AI 助手进入本项目时的首要入口。请完整阅读后再开始工作。 -->

## 项目概述

FreeFight 是一个 **Godot 4.6 单机线框 Demo**，核心玩法为实时生存战斗 + 策略部署 + 共鸣演化。**玩家唯一操作 = 从 3 张候选中选 1 张拖到战场某位置**；其余 2 张自动弃掉。怪物固定在部署位置不动，英雄自动巡猎（走向最近怪物近战攻击）。被动技能、属性成长、共鸣推进均自动结算。一个 Run = 4 场递进战斗（前 3 场养成 + 第 4 场 Boss 战）。

**关键词**：实时战斗、3 选 1 候选、英雄巡猎、怪物固定、战场地形、怪物机制差异化、共鸣被动技能、模式识别 Combo、精英变体、无回合 / 无主动技能

## 必读文档

在修改代码前，请阅读以下文档：

| 优先级 | 文档 | 作用 |
|--------|------|------|
| **必读** | [docs/rules/development-scope.md](docs/rules/development-scope.md) | 开发边界与禁止事项 |
| **必读** | [docs/knowledge/09-v5-策略性重做设计.md](docs/knowledge/09-v5-策略性重做设计.md) | **v5 设计定稿**（唯一事实来源）|
| 参考 | [docs/knowledge/README.md](docs/knowledge/README.md) | 文档索引 |
| 归档 | docs/knowledge/06,07,08-v2-*.md | v2~v4 历史，已被 v5 取代 |

## 核心规则（摘要）

> 完整规则见 `docs/rules/development-scope.md`

1. **实时制**：本项目没有回合、轮次、turn 概念
2. **玩家唯一操作 = 部署**：除了"3 选 1 + 部署位置"，玩家不做任何其他操作（无主动技能、无弃牌按钮、无装备穿卸、无抉择弹窗）
3. **无装备 / 无持仓 debuff**（v5 移除）
4. **无自动刷怪**：怪物只能由玩家拖拽部署产生（Boss 召唤除外）
5. **无部署格 / 无远近分区**：拖拽落点 = 怪物出现位置，战场为整片自由区
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
  - RunManager     (Run 4 场 + 击杀属性自动累计 + 跨场保留)

数据层: Resource (.tres) + RefCounted (静态定义)
  - CombatStats / MonsterData / BuffDef / BuffInstance
  - EvolutionPath / CardPool / HybridEvolution / BossData
  - TerrainType (Object, 枚举: 共鸣祭坛/荆棘地/圣光圈/暗影域/共鸣节点/腐毒地)

战斗核心:
  - CombatUnit (薄基类)
    → Hero (巡猎模式: 自动走向最近怪物 + 近战攻击 + 被动技能)
    → Monster (固定不动, 含 7 种独特机制)
  - BattleController._physics_process: 战斗循环 + 地形 tick + CD
  - 部署: 拖拽 → BattlefieldDropZone(全场自由区) → DeployManager
  - 候选: 3 张固定，部署后 2s CD，CD 结束后刷新（CardHand）
  - TerrainSystem: 管理两类地形：
    1. 地图地形（MapTerrainZone）：灵泉/水晶矿/岩地/荆棘丛，开局随机 3-4 个，永久存在
    2. 范围效果（TerrainCell）：共鸣 Tier II/III 被动召唤，6-8 秒临时
  - ComboTracker: 模式识别（生态专精 / 异种联动 / 密集部署）
  - EvolutionTracker: 共鸣进度 → 21 个被动 + 8 混合机制
  - FriendlySkeleton / UndeadAura: 友方召唤物

怪物机制（v5）:
  史莱姆死亡分裂 / 蝙蝠飞行 / 狼群族加速 / 哥布林死亡爆炸
  骷髅墓碑复活 / 石像鬼永久防御光环 / 毒蛇死亡毒池

英雄基础: 150 HP / 10 攻 / 3 防 / 1.0 攻速 / 180 移速 / 48 近战射程
部署 CD: 2.0s | 手牌候选: 3 张 | 精英概率: 10% | Combo 窗口: 4s
地图地形: 3-4 个永久区域(灵泉/水晶矿/岩地/荆棘丛)
范围效果: 被动召唤(6-8s 临时)
Run: 4 场（前 3 场击杀 12/18/24 + 60s | 第 4 场 Boss）
难度倍率: 1.0 / 1.2 / 1.5 / 2.0
伤害公式: max(1, atk - max(0, def - armor_penetration))
```

## 目录结构

```
res://
├── autoload/          # Autoload 单例（GameManager / DataRegistry / RunManager）
├── data/              # Resource 类定义 + TerrainType 枚举
├── resources/         # 怪物 / 共鸣 / 卡池 .tres
│                      # （已无 equipment/buffs/combos 目录 — v5 移除）
├── scenes/            # 场景（主菜单 / 图鉴 / 战斗）
├── scripts/
│   ├── battle/        # 战斗核心 + TerrainSystem + FriendlySkeleton + UndeadAura
│   └── ui/
├── assets/            # 简单贴图
└── docs/              # 项目文档（09-v5 为现行设计）
    ├── knowledge/     # 技术文档
    ├── plans/         # 开发计划归档
    └── rules/         # 开发规则
```
