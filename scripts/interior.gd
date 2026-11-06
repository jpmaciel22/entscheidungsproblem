extends Node3D
## Recepção e três salas, com arquitetura procedural e móveis importados.

signal solicitar_questoes(indice: int)

const Config = preload("res://scripts/configuracao.gd")
const Porta = preload("res://scripts/porta.gd")
const Terminal = preload("res://scripts/terminal_sala.gd")
const Mesa = preload("res://scenes/moveis/mesa.tscn")
const Cadeira = preload("res://scenes/moveis/cadeira.tscn")
const Banco = preload("res://scenes/moveis/banco_externo.tscn")
var mundo: Node3D
var livros_por_cor: Dictionary = {}


# Monta o interior e agrupa os livros em poucas chamadas de desenho.
func _ready() -> void:
	for bloco in Config.INTERIOR_BLOCOS:
		criar_peca(bloco[0], bloco[1], bloco[2], bloco[3], bloco[4])
	for bloco in Config.GUIA_ENTRADA:
		criar_peca(bloco[0], bloco[1], bloco[2], bloco[3], bloco[4])
	for estante in Config.ESTANTES_RECEPCAO:
		criar_estante(estante[0], estante[1])
	for posicao in Config.MESAS_RECEPCAO:
		criar_mesa(posicao)
	for indice in range(Config.SALAS.size()):
		criar_sala(indice)
	criar_livros_agrupados()
	criar_iluminacao()


# Cria uma peça da biblioteca na camada iluminada pelas luzes internas.
func criar_peca(titulo: String, tamanho: Vector3, posicao: Vector3, cor: String, solido: bool = false, angulo: float = 0.0) -> MeshInstance3D:
	var peca: MeshInstance3D = mundo.criar_caixa(titulo, tamanho, posicao, cor, solido)
	peca.layers = Config.CAMADA_INTERIOR
	peca.rotation.y = angulo
	return peca


# Forma cada sala com painel à esquerda, um banco e um quadro à direita.
func criar_sala(indice: int) -> void:
	var dados: Dictionary = Config.SALAS[indice]
	var origem := Vector3(dados["x"], 0, Config.SALA_FRENTE_Z)
	for parte in Config.SALA_PAREDE_PARTES:
		criar_peca("ParedeSala", parte[0], origem + parte[1], "parede_interna", true)
	for parte in Config.PORTA_SALA_MOLDURAS:
		criar_peca("MolduraSala", parte[0], origem + parte[1], "pedra")
	criar_peca("PlacaSala", Config.SALA_PLACA_TAMANHO, origem + Config.SALA_PLACA_OFFSET, "placa_fundo")
	criar_texto(dados["nome"], origem + Config.SALA_NOME_OFFSET, Config.SALA_NOME_ESCALA)
	criar_peca("TapeteSala", Config.SALA_TAPETE_TAMANHO, origem + Config.SALA_TAPETE_OFFSET, "tapete")
	criar_banco_sala(indice, origem)
	criar_quadro_sala(indice, origem, dados["quadro"])
	var porta := Porta.new()
	porta.name = "PortaSala%d" % (indice + 1)
	porta.assunto = dados["nome"]
	porta.position = origem + Config.PORTA_SALA_OFFSET
	porta.materiais = mundo.materiais
	add_child(porta)
	var terminal := Terminal.new()
	terminal.name = "TerminalSala%d" % (indice + 1)
	terminal.indice_sala = indice
	terminal.position = origem + Config.TERMINAL_OFFSET
	terminal.rotation.y = Config.TERMINAL_ANGULO
	terminal.materiais = mundo.materiais
	terminal.solicitar_questoes.connect(func(sala: int) -> void: solicitar_questoes.emit(sala))
	add_child(terminal)


# Usa o mesmo banco GLB do pátio, iluminado pelas luzes da sala e voltado ao painel.
func criar_banco_sala(indice: int, origem: Vector3) -> void:
	var banco := Banco.instantiate()
	banco.name = "BancoSala%d" % (indice + 1)
	banco.position = origem + Config.SALA_BANCO_OFFSET
	banco.rotation.y = Config.SALA_BANCO_ANGULO
	banco.camada_luz = Config.CAMADA_INTERIOR
	add_child(banco)


# Emoldura a imagem sem esticá-la: ajusta suas dimensões ao espaço disponível.
func criar_quadro_sala(indice: int, origem: Vector3, caminho: String) -> void:
	var textura := load(caminho) as Texture2D
	if textura == null:
		push_warning("Não foi possível carregar o quadro: " + caminho)
		return
	var quadro := Node3D.new()
	quadro.name = "QuadroSala%d" % (indice + 1)
	quadro.position = origem + Config.SALA_QUADRO_OFFSET
	quadro.rotation.y = Config.SALA_QUADRO_ANGULO
	add_child(quadro)
	var proporcao := textura.get_size()
	var fator := minf(Config.SALA_QUADRO_LIMITE.x / proporcao.x, Config.SALA_QUADRO_LIMITE.y / proporcao.y)
	var tamanho := proporcao * fator
	var moldura := criar_peca("MolduraQuadro", Vector3(tamanho.x + Config.SALA_QUADRO_BORDA * 2.0, tamanho.y + Config.SALA_QUADRO_BORDA * 2.0, Config.SALA_QUADRO_ESPESSURA), Vector3.ZERO, Config.SALA_QUADRO_COR)
	moldura.reparent(quadro, false)
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	var malha := QuadMesh.new()
	malha.size = tamanho
	malha.material = material
	var imagem := MeshInstance3D.new()
	imagem.name = "ImagemQuadro"
	imagem.mesh = malha
	imagem.position.z = Config.SALA_QUADRO_IMAGEM_Z
	imagem.layers = Config.CAMADA_INTERIOR
	imagem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quadro.add_child(imagem)


# Escreve as placas com o fundo e o texto exatos da paleta solicitada.
func criar_texto(texto: String, posicao: Vector3, escala: float) -> void:
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.position = posicao
	rotulo.pixel_size = escala
	rotulo.font_size = Config.FONTE_3D_TAMANHO
	rotulo.modulate = Config.CORES["placa_texto"]
	rotulo.outline_size = 0
	rotulo.layers = Config.CAMADA_INTERIOR
	add_child(rotulo)


# Monta a estante e usa apenas uma caixa de colisão para toda a mobília.
func criar_estante(posicao: Vector3, angulo: float = 0.0) -> void:
	var base := Transform3D(Basis(Vector3.UP, angulo), posicao)
	for parte in Config.ESTANTE_PARTES:
		criar_peca("Estante", parte[0], base * parte[1], "estante", false, angulo)
	for altura in Config.ESTANTE_PRATELEIRAS_Y:
		criar_peca("Prateleira", Config.ESTANTE_PRATELEIRA_TAMANHO, base * Vector3(0, altura, 0), "estante", false, angulo)
	var corpo := StaticBody3D.new()
	corpo.transform = base
	var forma := BoxShape3D.new()
	forma.size = Config.ESTANTE_COLISAO_TAMANHO
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position = Config.ESTANTE_COLISAO_OFFSET
	corpo.add_child(colisao)
	add_child(corpo)
	registrar_livros(base)


# Alterna altura e cor das lombadas sem criar um nó para cada livro.
func registrar_livros(base: Transform3D) -> void:
	for nivel in range(Config.LIVROS_BASE_Y.size()):
		for indice in range(Config.LIVROS_POR_PRATELEIRA):
			var cor := (indice + nivel) % Config.LIVRO_ALTURAS.size()
			var altura: float = Config.LIVRO_ALTURAS[cor]
			var tamanho := Vector3(Config.LIVRO_LARGURA, altura, Config.LIVRO_PROFUNDIDADE)
			var posicao := Vector3(Config.LIVRO_INICIO_X + indice * Config.LIVRO_PASSO_X, Config.LIVROS_BASE_Y[nivel] + altura / 2.0, Config.LIVRO_POSICAO_Z)
			var transformacao := base * Transform3D(Basis.from_scale(tamanho), posicao)
			if not livros_por_cor.has(cor):
				livros_por_cor[cor] = []
			livros_por_cor[cor].append(transformacao)


# Desenha todos os livros em cinco grupos, um por cor da paleta.
func criar_livros_agrupados() -> void:
	for indice in livros_por_cor:
		var malha := BoxMesh.new()
		malha.size = Vector3.ONE
		malha.material = mundo.materiais["livro_%d" % indice]
		var grupo := MultiMesh.new()
		grupo.transform_format = MultiMesh.TRANSFORM_3D
		grupo.mesh = malha
		grupo.instance_count = livros_por_cor[indice].size()
		for i in range(grupo.instance_count):
			grupo.set_instance_transform(i, livros_por_cor[indice][i])
		var objeto := MultiMeshInstance3D.new()
		objeto.name = "LivrosCor%d" % indice
		objeto.multimesh = grupo
		objeto.layers = Config.CAMADA_INTERIOR
		objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(objeto)


# Instancia a mesa GLB e duas cadeiras voltadas para ela, com colisões próprias.
func criar_mesa(posicao: Vector3) -> void:
	var mesa := Mesa.instantiate() as Node3D
	mesa.position = posicao + Config.MOVEIS_PISO_OFFSET
	add_child(mesa)
	for lugar in Config.CADEIRAS_RECEPCAO:
		var cadeira := Cadeira.instantiate() as Node3D
		cadeira.position = posicao + Config.MOVEIS_PISO_OFFSET + lugar[0]
		cadeira.rotation.y = lugar[1]
		add_child(cadeira)


# Ilumina a biblioteca com duas luzes suaves, sem sombras ou materiais emissivos.
func criar_iluminacao() -> void:
	for posicao in Config.LUZES_INTERIORES:
		var luz := OmniLight3D.new()
		luz.position = posicao
		luz.light_color = Config.CORES["luz_interna"]
		luz.light_energy = Config.LUZ_INTERIOR_ENERGIA
		luz.omni_range = Config.LUZ_INTERIOR_ALCANCE
		luz.omni_attenuation = Config.LUZ_INTERIOR_ATENUACAO
		luz.light_cull_mask = Config.CAMADA_INTERIOR
		luz.shadow_enabled = false
		add_child(luz)
		criar_peca("Luminaria", Config.LUMINARIA_TAMANHO, posicao, "estante")
		criar_peca("Difusor", Config.LUMINARIA_DETALHE, posicao + Config.LUMINARIA_DETALHE_OFFSET, "placa_fundo")
