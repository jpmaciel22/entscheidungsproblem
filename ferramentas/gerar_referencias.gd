extends SceneTree
## Exporta cópias visuais do mundo e dos objetos para estudo no Blender.
## Não altera as cenas usadas pelo jogo. Textos continuam sendo gerados no Godot.

const Config = preload("res://scripts/configuracao.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Interior = preload("res://scripts/interior.gd")
const Porta = preload("res://scripts/porta.gd")
const Terminal = preload("res://scripts/terminal_sala.gd")
const PASTA := "res://referencias/objetos/"
var manifesto: Array = []
var falhas := 0


# Aguarda a árvore antes de montar e copiar o mundo procedural.
func _initialize() -> void:
	call_deferred("gerar")


# Gera o conjunto completo e as versões individuais dos objetos.
func gerar() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Gere as referências com Compatibility e sem --headless, para preservar os livros MultiMesh.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	var mundo := Mundo.new()
	root.add_child(mundo)
	var completo := copiar_visual(mundo)
	completo.name = "MundoCompleto"
	exportar(completo, "mundo_completo", false)
	var interior := Node3D.new()
	interior.name = "InteriorBiblioteca"
	for filho in mundo.get_children():
		if filho.name == "Interior" or (filho is MeshInstance3D and filho.layers == Config.CAMADA_INTERIOR):
			var copia := copiar_visual(filho)
			if copia != null:
				interior.add_child(copia)
	var biblioteca := criar_objeto("biblioteca_exterior")
	for filho in interior.get_children():
		biblioteca.add_child(filho.duplicate())
	exportar(biblioteca, "biblioteca_completa", false)
	exportar(interior, "biblioteca_interior", false)
	for tipo in ["biblioteca_exterior", "terreno_patio", "arvore_padrao", "banco_externo", "mesa_com_banquetas", "banqueta", "estante_com_livros", "porta_entrada", "porta_sala", "janela", "tapete", "luminaria", "painel_questoes", "placa_sala", "pilastra", "frontao", "vaso"]:
		exportar(criar_objeto(tipo), tipo, tipo != "biblioteca_exterior" and tipo != "terreno_patio")
	for indice in range(Config.LIVRO_ALTURAS.size()):
		exportar(criar_livro(indice), "livro_%d" % (indice + 1), true)
	mundo.free()
	var arquivo := FileAccess.open("res://referencias/manifesto.json", FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(manifesto, "\t"))
	print("REFERENCIAS: ", manifesto.size(), " arquivos GLB; falhas: ", falhas)
	await process_frame
	await RenderingServer.frame_post_draw
	quit(falhas)


# Constrói apenas a peça solicitada com as mesmas funções e medidas do jogo.
func criar_objeto(tipo: String) -> Node3D:
	var construtor := Mundo.new()
	construtor.criar_materiais()
	var interior := Interior.new()
	interior.mundo = construtor
	var extra := Node3D.new()
	match tipo:
		"biblioteca_exterior":
			construtor.criar_biblioteca()
		"terreno_patio":
			construtor.criar_terreno()
		"arvore_padrao":
			construtor.criar_arvore(Vector3.ZERO)
		"banco_externo":
			for parte in Config.BANCO_PARTES:
				construtor.criar_caixa("Banco", parte[0], parte[1], parte[2], false)
		"mesa_com_banquetas":
			interior.criar_mesa(Vector3.ZERO)
		"banqueta":
			construtor.criar_caixa("Assento", Config.BANQUETA_ASSENTO, Config.BANQUETA_ASSENTO_OFFSET, "mesa", false)
			construtor.criar_caixa("Base", Config.BANQUETA_BASE, Config.BANQUETA_BASE_OFFSET, "estante", false)
		"estante_com_livros":
			interior.criar_estante(Vector3.ZERO)
			interior.criar_livros_agrupados()
		"porta_entrada":
			construtor.criar_porta()
		"porta_sala":
			var porta := Porta.new()
			porta.materiais = construtor.materiais
			porta.position = Config.PORTA_SALA_OFFSET
			extra.add_child(porta)
		"janela":
			construtor.criar_janela(0)
		"tapete":
			construtor.criar_caixa("Tapete", Config.SALA_TAPETE_TAMANHO, Vector3.ZERO, "tapete", false)
		"luminaria":
			construtor.criar_caixa("Corpo", Config.LUMINARIA_TAMANHO, Vector3.ZERO, "estante", false)
			construtor.criar_caixa("Difusor", Config.LUMINARIA_DETALHE, Config.LUMINARIA_DETALHE_OFFSET, "placa_fundo", false)
		"painel_questoes":
			var terminal := Terminal.new()
			terminal.materiais = construtor.materiais
			terminal.position = Vector3(0, Config.TERMINAL_OFFSET.y, 0)
			extra.add_child(terminal)
		"placa_sala":
			construtor.criar_caixa("Placa", Config.SALA_PLACA_TAMANHO, Vector3.ZERO, "placa_fundo", false)
		"pilastra":
			for parte in Config.COLUNA_PARTES:
				construtor.criar_caixa("Pilastra", parte[0], parte[1], "pedra", false)
		"frontao":
			var prisma := PrismMesh.new()
			prisma.size = Config.FRONTON_TAMANHO
			construtor.criar_malha("Frontao", prisma, Vector3.ZERO, Config.FRONTON_COR)
		"vaso":
			construtor.criar_caixa("Vaso", Config.VASO_TAMANHO, Config.VASO_OFFSET, "rodape", false)
	# Porta e terminal precisam de _ready para criar suas peças.
	root.add_child(extra)
	var resultado := Node3D.new()
	resultado.name = tipo.to_pascal_case()
	for origem in [construtor, interior, extra]:
		for filho in origem.get_children():
			var copia := copiar_visual(filho)
			if copia != null:
				resultado.add_child(copia)
	construtor.free()
	interior.free()
	extra.free()
	return resultado


# Exporta cada cor e altura de livro como uma peça independente.
func criar_livro(indice: int) -> Node3D:
	var construtor := Mundo.new()
	construtor.criar_materiais()
	var tamanho := Vector3(Config.LIVRO_LARGURA, Config.LIVRO_ALTURAS[indice], Config.LIVRO_PROFUNDIDADE)
	var objeto := construtor.criar_caixa("Livro", tamanho, Vector3.ZERO, "livro_%d" % indice, false)
	var resultado := Node3D.new()
	resultado.add_child(copiar_visual(objeto))
	construtor.free()
	return resultado


# Copia só objetos visuais. Placas saem sem texto; câmeras e física não são exportadas.
func copiar_visual(original: Node) -> Node3D:
	if not original is Node3D or original is Label3D or original is Camera3D or original is Light3D or original is CharacterBody3D or original is CollisionShape3D:
		return null
	var copia: Node3D
	if original is MeshInstance3D:
		var objeto := MeshInstance3D.new()
		objeto.mesh = original.mesh
		objeto.material_override = original.material_override
		if original.mesh != null:
			for i in range(original.mesh.get_surface_count()):
				objeto.set_surface_override_material(i, original.get_surface_override_material(i))
		copia = objeto
	elif original is MultiMeshInstance3D:
		copia = Node3D.new()
		if original.multimesh != null:
			for i in range(original.multimesh.instance_count):
				var objeto := MeshInstance3D.new()
				objeto.name = "Livro%d" % (i + 1)
				objeto.mesh = original.multimesh.mesh
				objeto.transform = original.multimesh.get_instance_transform(i)
				copia.add_child(objeto)
	else:
		copia = Node3D.new()
	copia.name = original.name
	copia.transform = original.transform
	for filho in original.get_children():
		var visual := copiar_visual(filho)
		if visual != null:
			copia.add_child(visual)
	if not copia is MeshInstance3D and copia.get_child_count() == 0:
		copia.free()
		return null
	return copia


# Salva GLB e anota dimensões reais; peças pequenas recebem origem na base.
func exportar(objeto: Node3D, nome: String, centralizar: bool) -> void:
	root.add_child(objeto)
	var limites := obter_limites(objeto)
	if centralizar:
		var base := Vector3(limites.get_center().x, limites.position.y, limites.get_center().z)
		for filho: Node3D in objeto.get_children():
			filho.position -= base
		limites = obter_limites(objeto)
	var documento := GLTFDocument.new()
	var estado := GLTFState.new()
	var erro := documento.append_from_scene(objeto, estado)
	if erro == OK:
		erro = documento.write_to_filesystem(estado, PASTA + nome + ".glb")
	if erro != OK:
		falhas += 1
		push_error("Falha na referência: " + nome)
	else:
		var quantidade := objeto.find_children("*", "MeshInstance3D", true, false).size()
		manifesto.append({"arquivo": nome + ".glb", "malhas": quantidade,
			"dimensoes_xyz_m": [limites.size.x, limites.size.y, limites.size.z],
			"origem_na_base": centralizar, "textos_incluidos": false})
		print("GLB: ", nome, " · ", quantidade, " malhas · dimensões ", limites.size)
	objeto.free()


# Calcula as medidas a partir das malhas transformadas, incluindo os livros instanciados.
func obter_limites(objeto: Node3D) -> AABB:
	var resultado := AABB()
	var primeiro := true
	for malha: MeshInstance3D in objeto.find_children("*", "MeshInstance3D", true, false):
		if malha.mesh == null:
			continue
		var relativo := objeto.global_transform.affine_inverse() * malha.global_transform
		var caixa := relativo * malha.mesh.get_aabb()
		resultado = caixa if primeiro else resultado.merge(caixa)
		primeiro = false
	return resultado
