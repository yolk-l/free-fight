# FreeFight - AI 协作指南

<!-- AI-CONTEXT: 本文件是 AI 助手进入本项目时的首要入口。请完整阅读后再开始工作。 -->

## 项目概述

FreeFight 是一个 **Godot 4.6 单机线框 Demo**，核心玩法为实时生存战斗：玩家拖拽手牌部署怪物，怪物攻击英雄，英雄自动反击，英雄死亡即 Game Over。

**关键词**：实时战斗、拖拽部署、持仓负面、无回合/无轮次

## 必读文档

在修改代码前，请阅读以下文档：

| 优先级 | 文档 | 作用 |
|--------|------|------|
| **必读** | [docs/rules/development-scope.md](docs/rules/development-scope.md) | 开发边界与禁止事项 |
| **必读** | [docs/knowledge/README.md](docs/knowledge/README.md) | 技术文档索引 |
| 参考 | [docs/plans/freefight_demo_计划.md](docs/plans/freefight_demo_计划.md) | 里程碑归档 |
| 参考 | [docs/knowledge/03-战斗系统.md](docs/knowledge/03-战斗系统.md) | 战斗循环实现细节 |
| 参考 | [docs/knowledge/02-数据层.md](docs/knowledge/02-数据层.md) | Resource/数据模型 |
| 参考 | [docs/knowledge/08-v2-数值初稿.md](docs/knowledge/08-v2-数值初稿.md) | 数值拍板（调参唯一来源） |

## 核心规则（摘要）

> 完整规则见 `docs/rules/development-scope.md`

1. **实时制**：本项目没有回合、轮次、turn 概念，禁止引入回合制机制或术语
2. **无自动刷怪**：怪物只能由玩家拖拽手牌部署产生，禁止任何形式的自动生成
3. **无部署格**：禁止 DeploySlot、点击出牌等已移除机制
4. **最小改动**：只改与任务直接相关的文件，不顺手重构
5. **先问再做**：需求含糊或超出允许范围时，先向用户确认
6. **线框 Demo 定位**：UI 用 ColorRect/Panel/Label，不引入正式美术

## 架构速查

```
引擎: Godot 4.6 | 语言: GDScript
入口: res://scenes/main_menu.tscn

Autoload:
  - GameManager    (跨场景状态)
  - DataRegistry   (数据注册)

数据层: Resource (.tres)
  - CombatStats / MonsterData / EquipmentData / BuffDef

战斗核心:
  - CombatUnit (薄基类) → Hero (有装备) / Monster (无装备)
  - BattleController._physics_process → tick_combat
  - 部署: 拖拽 → BattlefieldDropZone → DeployManager

伤害公式: max(1, atk - def)
英雄基准: 120 HP
手牌上限: 7
弃牌冷却: 10s
```

## 目录结构

```
res://
├── autoload/          # Autoload 单例
├── data/              # Resource 类定义 (.gd)
├── resources/         # 配置实例 (.tres)
├── scenes/            # 场景 (.tscn)
├── scripts/           # 逻辑脚本
├── assets/            # 简单贴图
└── docs/              # 项目文档（本目录）
    ├── knowledge/     # 技术文档
    ├── plans/         # 开发计划归档
    └── rules/         # 开发规则
```
