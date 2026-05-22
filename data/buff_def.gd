class_name BuffDef
extends Resource

enum DurationType { PERMANENT, TIMED, COUNTED }

@export var id: StringName = &""
@export var display_name: String = ""
@export var is_debuff: bool = false
@export var duration_type: DurationType = DurationType.PERMANENT
@export var duration_sec: float = 0.0
@export var duration_count: int = 0
@export var trigger_event: StringName = &""
@export var max_stacks: int = 1
@export var modifiers: Dictionary = {}
