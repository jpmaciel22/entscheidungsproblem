@tool
extends Node3D
## Cena opcional de árvores posicionadas pelo usuário. A referência existe só no editor.

const Config = preload("res://scripts/configuracao.gd")
const ModeloBiblioteca = preload("res://assets/biblioteca.glb")


# Mostra um guia no editor; no jogo, configura apenas os modelos posicionados.
func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("criar_referencia")
	else:
		for arvore in obter_arvores():
			configurar_modelo(arvore)
			criar_colisao_tronco(arvore)


# Distingue modelos reais dos nós de referência que não são salvos na cena.
func obter_arvores() -> Array[Node3D]:
	var arvores: Array[Node3D] = []
	for filho in get_children():
		if filho is Node3D and filho.name != Config.PREVIA_NOME:
			if filho is MeshInstance3D or not filho.find_children("*", "MeshInstance3D", true, false).is_empty():
				arvores.append(filho)
	return arvores


# Informa ao mundo se deve substituir as árvores primitivas pelas personalizadas.
func tem_arvores_personalizadas() -> bool:
	return not obter_arvores().is_empty()


# Mantém os materiais foscos, sem emissão e sem sombras, preservando o modelo original.
func configurar_modelo(arvore: Node3D) -> void:
	var malhas: Array = arvore.find_children("*", "MeshInstance3D", true, false)
	if arvore is MeshInstance3D:
		malhas.append(arvore)
	for objeto: MeshInstance3D in malhas:
		objeto.layers = Config.CAMADA_EXTERIOR
		objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if objeto.mesh == null:
			continue
		for superficie in range(objeto.mesh.get_surface_count()):
			var original := objeto.get_active_material(superficie)
			if original is BaseMaterial3D:
				var material := original.duplicate() as BaseMaterial3D
				material.roughness = 1.0
				material.metallic = 0.0
				material.metallic_specular = 0.0
				material.emission_enabled = false
				if objeto.material_override != null:
					objeto.material_override = material
				else:
					objeto.set_surface_override_material(superficie, material)


# Adiciona uma colisão simples na base, se o modelo ainda não tiver colisão própria.
func criar_colisao_tronco(arvore: Node3D) -> void:
	if arvore is CollisionObject3D or not arvore.find_children("*", "CollisionObject3D", true, false).is_empty():
		return
	var corpo := StaticBody3D.new()
	corpo.name = "ColisaoDoTronco"
	var forma := CapsuleShape3D.new()
	forma.radius = Config.ARVORE_PERSONALIZADA_COLISAO_RAIO
	forma.height = Config.ARVORE_PERSONALIZADA_COLISAO_ALTURA
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position.y = Config.ARVORE_PERSONALIZADA_COLISAO_ALTURA / 2.0
	corpo.add_child(colisao)
	arvore.add_child(corpo)


# Mostra a biblioteca atual na cena de paisagismo sem gravá-la no .tscn.
func criar_referencia() -> void:
	if not is_inside_tree():
		return
	var antiga := get_node_or_null(Config.PREVIA_NOME)
	if antiga != null:
		remove_child(antiga)
		antiga.queue_free()
	var referencia := Node3D.new()
	referencia.name = Config.PREVIA_NOME
	add_child(referencia)
	var predio := ModeloBiblioteca.instantiate() as Node3D
	predio.position = Config.BIBLIOTECA_MODELO_POSICAO
	predio.rotation.y = Config.BIBLIOTECA_MODELO_ROTACAO
	predio.scale = Config.BIBLIOTECA_MODELO_ESCALA
	referencia.add_child(predio)
	var chao := BoxMesh.new()
	chao.size = Config.TERRENO[0][1]
	var material_chao := StandardMaterial3D.new()
	material_chao.albedo_color = Config.CORES["grama"]
	material_chao.roughness = 1.0
	criar_malha_referencia(referencia, chao, Config.TERRENO[0][2], material_chao)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Config.SOL_ROTACAO
	sol.light_color = Config.SOL_COR
	sol.light_energy = Config.SOL_ENERGIA
	sol.shadow_enabled = false
	referencia.add_child(sol)
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Config.CEU_TOPO
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Config.AMBIENTE_COR
	ambiente.ambient_light_energy = Config.AMBIENTE_ENERGIA
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	referencia.add_child(mundo)


# Acrescenta uma peça visual sem colisão nem scripts de jogo à referência.
func criar_malha_referencia(pai: Node3D, malha: Mesh, posicao: Vector3, material: Material) -> void:
	var objeto := MeshInstance3D.new()
	objeto.mesh = malha
	objeto.position = posicao
	objeto.material_override = material
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(objeto)
