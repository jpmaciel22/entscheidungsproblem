extends StaticBody3D
## Modelos GLB com colisão simples e a mesma iluminação do ambiente onde ficam.

@export_flags_3d_render var camada_luz: int = 1


func _ready() -> void:
	for malha: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		malha.layers = camada_luz
		malha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
