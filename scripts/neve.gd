extends Node3D
## Partículas nativas do Godot, restritas ao exterior e suspensas dentro do prédio.

const Config = preload("res://scripts/configuracao.gd")
var jogador: Node3D
var emissores: Array[CPUParticles3D] = []


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	var floco := SphereMesh.new()
	floco.radius = Config.NEVE_FLOCO_RAIO
	floco.height = Config.NEVE_FLOCO_RAIO * 2.0
	floco.radial_segments = 4
	floco.rings = 1
	floco.material = material
	for dados in Config.NEVE_AREAS:
		var area: Rect2 = dados[0]
		var centro := area.get_center()
		var particulas := CPUParticles3D.new()
		particulas.name = "Flocos%d" % (emissores.size() + 1)
		particulas.mesh = floco
		particulas.amount = dados[1]
		particulas.lifetime = Config.NEVE_DURACAO
		particulas.preprocess = Config.NEVE_DURACAO
		particulas.local_coords = false
		particulas.position = Vector3(centro.x, Config.NEVE_ALTURA, centro.y)
		particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		particulas.emission_box_extents = Vector3(area.size.x / 2.0, 1.0, area.size.y / 2.0)
		# Queda vertical para os flocos não atravessarem as paredes e a cobertura.
		particulas.direction = Vector3.DOWN
		particulas.spread = 0.0
		particulas.gravity = Vector3(0, -0.12, 0)
		particulas.initial_velocity_min = 1.3
		particulas.initial_velocity_max = 1.7
		particulas.scale_amount_min = 0.6
		particulas.scale_amount_max = 1.2
		particulas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(particulas)
		emissores.append(particulas)
	atualizar_exterior()


func _process(_delta: float) -> void:
	atualizar_exterior()


# Oculta também os flocos já emitidos assim que o jogador cruza a entrada.
func atualizar_exterior() -> void:
	if not is_instance_valid(jogador):
		return
	var fora := not Config.BIBLIOTECA_INTERIOR.has_point(jogador.position)
	for particulas in emissores:
		particulas.visible = fora
		particulas.emitting = fora
		particulas.speed_scale = 1.0 if fora else 0.0
