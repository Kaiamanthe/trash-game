extends Node3D

# Signals
signal on_pole_ready
signal on_cast

@onready var bobber: CharacterBody3D = $Bobber
@onready var line: MeshInstance3D = $Line
@onready var mark_line_end: Marker3D = $Pole/Mark_LineStart
@onready var mark_line_start: Marker3D = $Bobber/Mark_LineEnd

# Inicialize the overloaded _physics_process
func _ready() -> void:
	bobber.set_physics_process(false)
	line.hide()
	
	#Connections
	#init
	on_pole_ready.connect(bobber.on_pole_ready)
	on_pole_ready.connect(line.on_pole_ready)
	
	#cast
	on_cast.connect(bobber.on_cast)
	on_cast.connect(line.on_cast)


# Overides the Phycis process of bobber
func _physics_process(_delta: float) -> void:
	line._refresh_line()

func pole_ready():
	on_pole_ready.emit()

func on_cast_started():
	on_cast.emit()
