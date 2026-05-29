<!-- AI-CONTEXT: 本文件为项目里程碑归档，所有阶段已完成。了解项目演进历史时参考此文件。 -->

# FreeFight 单机 Demo 开发计划

> **文档角色**：本文件为计划归档 + 里程碑索引；**现行实现细节**以 [`docs/knowledge/README.md`](../knowledge/README.md) 为准（尤其 [03-战斗系统](../knowledge/03-战斗系统.md)、[02-数据层](../knowledge/02-数据层.md)、[08-v2-数值初稿](../knowledge/08-v2-数值初稿.md)）。  
> **边界规则**：[`development-scope.md`](../rules/development-scope.md)

## 项目现状（截至 v4-Boss 完成）

- 引擎：**Godot 4.6**；入口 `res://scenes/main_menu.tscn`
- **已实现**：主菜单 / 图鉴 / 战斗全流程；`assets/` 简单贴图 + `wireframe_theme` 配色
- **部署**：拖拽手牌至 `BattlefieldDropZone` 松手部署（**无** `DeploySlot` / 点击出牌）；部署后满手补牌 + 2s 冷却
- **怪物来源**：仅玩家部署（Boss 召唤除外）；**无** `MonsterSpawner` / 自动刷怪；击杀不掉落卡牌
- **怪物种类**：7 种（史莱姆/蝙蝠/狼/哥布林/石像鬼/骷髅/毒蛇）
- **持仓负面**：Buff 系统实现，每种怪有独立 debuff（攻击/防御/流血）
- **演化**：7 条路径 × 3 阶 + 8 个混合被动
- **Combo**：10 个部署组合，4s 窗口
- **Run 结构**：4 场递进战斗（前 3 场养成 + 第 4 场 Boss 战），难度倍率递增，跨场保留 HP/装备/演化
- **Boss 系统**：4 个 Boss（铁甲巨兽/暗影刺客/腐朽巫师/亡灵领主），开局展示特性+克制提示，第 4 场 Boss 战
- **英雄基准**：150 HP / 10 攻 / 3 防 / 1.0 攻速

---

## 目标功能

| 包含（已实现） | 不包含（除非用户明确要求） |
|----------------|---------------------------|
| 主菜单、图鉴、生存战斗 | 技能 / 元素克制 |
| 拖拽部署、实时普攻、远程弹射 | 部署格、点击即时出牌 |
| 攻/防/HP/攻速、移速、穿甲、闪避 | 自动刷怪、波次胜利 |
| 掉落装备（不掉落卡牌）、品质+词缀 | 存档、联网、正式美术包 |
| 持仓负面 + 冷却弃牌 | — |
| 7 种怪物 + 10 个 combo | — |
| 7 条演化路径(3阶) + 8 混合被动 | — |
| 4 场 Run + 跨场保留 + Boss 战 | — |
| 4 个 Boss + 预览面板 + 特效 | — |
| 分怪掉落池、落点预览、威胁星级 | — |

---

## 架构总览

```mermaid
flowchart TD
    MainMenu[MainMenuScene] -->|开始游戏| Battle[BattleScene]
    MainMenu -->|图鉴| Codex[CodexScene]
    Battle -->|英雄死亡| GameOver[GameOverPanel]
    GameOver --> MainMenu
    Codex --> MainMenu

    subgraph autoloads [Autoload]
        GameManager[GameManager]
        DataRegistry[DataRegistry]
    end

    Battle --> BattleController
    BattleController --> HeroUnit
    BattleController --> CardHand
    BattleController --> BattlefieldDropZone
    BattleController --> DeployManager
    BattleController --> LootSystem

    DataRegistry --> MonsterData
    DataRegistry --> EquipmentData
    MonsterData --> HoldPenaltyStats
```

**核心原则**

- 配置：`Resource` + `.tres`；运行时：单位 `Node` + `base_stats.hp`
- `CombatUnit` 薄基类；`Hero` + `EquipmentInventory`；`Monster` 无装备
- 战斗节拍：`BattleController._physics_process` → `tick_combat`
- 持仓负面：**必须**用 `HoldPenaltyStats`（勿用 `CombatStats` 子资源）

---

## 目录结构（当前）

```
res://
├── autoload/
│   ├── game_manager.gd
│   ├── data_registry.gd
│   └── run_manager.gd
├── data/
│   ├── combat_stats.gd
│   ├── hold_penalty_stats.gd    # v2
│   ├── monster_data.gd
│   ├── equipment_data.gd
│   ├── boss_data.gd             # v4 Boss 数据
│   ├── game_config.gd
│   └── game_ids.gd
├── assets/
│   ├── hero.png
│   ├── monsters/{id}.png
│   ├── equipment/{id}.png
│   └── ui/*.png
├── resources/
│   ├── hero_default.tres        # 120 HP
│   ├── monsters/*.tres
│   └── equipment/*.tres
├── scenes/
│   ├── main_menu.tscn
│   ├── codex/codex_scene.tscn
│   └── battle/
│       ├── battle_scene.tscn
│       ├── hero_unit.tscn
│       ├── monster_unit.tscn
│       ├── loot_drop.tscn
│       └── ui/stat_bar.tscn
└── scripts/
    ├── battle/
    │   ├── battle_controller.gd
    │   ├── combat_unit.gd
    │   ├── hero.gd              # refresh_display()
    │   ├── monster.gd
    │   ├── equipment_inventory.gd
    │   ├── card_hand.gd
    │   ├── monster_card_ui.gd
    │   ├── battlefield_drop_zone.gd
    │   ├── deploy_manager.gd
    │   ├── loot_system.gd
    │   └── loot_drop.gd
    └── ui/
        ├── wireframe_theme.gd
        └── wireframe_button.gd
```

**已移除、勿恢复**：`deploy_slot.tscn`、`monster_spawner.gd`、`DeploySlot` 交互。

---

## 数据模型（摘要）

| 类型 | 说明 |
|------|------|
| `CombatStats` | 单位/装备属性；`apply_bonus` / `apply_penalty`（含 `MIN_*` 下限） |
| `HoldPenaltyStats` | 手牌持仓负面，默认 0；`merge_into(sum)` |
| `MonsterData` | `base_stats`、`hold_penalty`、`hold_bleed_per_sec`、`move_speed` |
| `GameConfig` | `ATTACK_RANGE=48`、`DISCARD_COOLDOWN_SEC=10`、`MIN_ATTACK/DEFENSE/ATTACK_SPEED` |

**伤害**：`max(1, atk - def)`（`CombatUnit.try_attack`）

**英雄有效属性**：基础 → 装备 → 持仓负面；StatBar 显示有效值。

物种持仓拍板（详见 08 §3）：史莱姆防 -1；狼攻 -2；哥布林攻 -2 防 -1 失血 0.6/s。

---

## 战斗场景布局（当前）

```
┌─────────────────────────────────────────────────────────┐
│ TopBar: 操作说明 | 存活时间                              │
│ [英雄区-左]              [BattlefieldDropZone-右]        │
│  Sprite2D + StatBar      拖拽松手部署，拖入高亮           │
├─────────────────────────────────────────────────────────┤
│ BottomPanel (VBox):                                      │
│   EquipmentBar → CardHand → HoldSummary → DiscardRow     │
│ BottomBg (贴图)                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 核心流程

### 部署（拖拽）

```mermaid
sequenceDiagram
    participant Player
    participant Card as MonsterCardUI
    participant Zone as BattlefieldDropZone
    participant BC as BattleController
    participant DM as DeployManager

    Player->>Card: 拖拽（按下不触发选中重建）
    Player->>Zone: 右侧战场松手
    Zone->>BC: card_dropped(id, global_pos)
    BC->>DM: deploy_monster_at
    BC->>CardHand: consume_card
```

- 点击选中：松开且移动 < 8px → 用于弃牌；再点同卡取消选中。

### 弃牌（v2）

1. 选手牌 → `BtnDiscard`（冷却 10s 就绪）
2. `discard_card` → 移除卡与持仓负面，重置冷却

### 失血（v2）

`BattleController._tick_hold_bleed`：每秒 `take_damage(max(1, ceil(bleed_sum)))`。

### 掉落

| 概率 | 类型 | 说明 |
|------|------|------|
| 60% | 装备 | 全表随机 id + 品质 + 前缀词缀，自动进背包 |
| 40% | 无 | — |

装备自动进入背包（8 格）；背包满丢弃最早的；点击格子装备。

### 失败

英雄 HP ≤ 0 → `GameOverPanel`；`set_physics_process(false)`。

---

## 分阶段里程碑（均已完成）

| 阶段 | 内容 |
|------|------|
| 1 | 骨架、Autoload、Resource、.tres |
| 2 | 主菜单、图鉴 |
| 3 | 战斗布局、StatBar |
| 4 | CombatUnit、Hero/Monster 分化 |
| 5 | **拖拽**手牌 + DeployManager（非部署格） |
| 6 | Game Over；**无** MonsterSpawner |
| 7 | LootSystem、装备、图鉴解锁 |
| 8 | 手牌上限 7、UI 打磨 |
| v2 | HoldPenaltyStats、持仓/失血、弃牌、HoldSummary |
| v3-1 | Run 结构（4 场递进、难度倍率、跨场保留） |
| v3-2 | 远程弹射攻击、部署区分区（近/中/远）、距离影响掉落品质 |
| v3-3 | Combo 系统（10 个配方、4s 窗口） |
| v3-4 | 演化系统（7 条路径 × 3 阶） |
| v3-5 | 混合演化（8 个交叉被动） |
| v3-6 | 部署后满手补牌 + 2s 部署冷却 |
| v3-7 | 新怪物（骷髅、毒蛇）+ 新 combo + 新演化路径 |
| v3-8 | 平衡调整（英雄 150HP/3防、持仓惩罚削弱） |
| v3-9 | P1 backlog（分怪掉落池、落点预览、威胁星级、手牌满提示） |
| v4 | Boss 系统（4 Boss + 预览面板 + Boss 战 + 特效 tick） |

---

## 验收标准（当前 Demo）

1. 主菜单 ↔ 图鉴 ↔ 战斗可切换
2. 拖拽手牌至右侧部署区生成怪物并移向英雄；部署后满手补牌，2s 冷却
3. 无自动刷怪；英雄远程弹射攻击最近怪，怪进射程普攻
4. 击杀掉落装备（品质+词缀）；近距离部署掉落更好；装备同槽覆盖；图鉴解锁
5. 留牌降低英雄有效属性（攻击/防御/流血）；部署或弃牌后负面消失
6. 弃牌 10s 冷却、无代价；冷却中按钮禁用
7. 4s 内按序部署触发 combo 效果
8. 击杀特定怪物推进演化（3 阶），两条路径达 Tier I 触发混合被动
9. 4 场 Run 递进战斗，HP/装备/演化跨场保留
10. 英雄死亡 Run 失败，可回主菜单
11. Run 开始时展示随机 Boss 信息（名称/属性/特性/克制提示），第 4 场 Boss 自动出现
12. Boss 特效生效（光环失血/再生/召唤），击杀 Boss 通关

---

## P1 backlog（已全部实现）

原 P1 backlog 已在 v3-9 阶段完成：分怪掉落池、落点预览、威胁星级、手牌满提示。

详见 [`docs/knowledge/05-依赖与扩展.md`](../../docs/knowledge/05-依赖与扩展.md)。

---

## 预估工作量（历史）

初版 v1 约 3～4 天；v2 持仓/弃牌约 2.5～3.5 天（均已落地）。后续以 playtest 调表为主（08 §10）。
