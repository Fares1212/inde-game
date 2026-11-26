extends Resource
class_name VesselData
@export var id: String
@export var title: String
@export var capacity: float
@export var scoop: float
@export var stroke_seconds: float
@export var spill_rate: float
@export var slowdown: float
@export var price: int
@export var gate: float
@export var delivery: int
@export var leverage: float
@export var auto_rate: float
@export var verb: String
@export_multiline var description: String
@export var model: PackedScene
@export var scoop_sound: String = "scoop"
