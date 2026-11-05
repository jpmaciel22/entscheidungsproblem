extends Node3D
## Biblioteca procedural. Todas as malhas são primitivas do Godot.

const Config = preload("res://scripts/configuracao.gd")
const Jogador = preload("res://scripts/jogador.gd")
const Interior = preload("res://scripts/interior.gd")
const Questionario = preload("res://scripts/questionario.gd")
const Fluxo = preload("res://scripts/fluxo_jogo.gd")
const Paisagismo = preload("res://scenes/paisagismo.tscn")
var materiais: Dictionary = {}
var camada_instrucoes: CanvasLayer


# Gera todos os elementos assim que a cena principal começa.
func _ready() -> void:
	criar_materiais()
	criar_ceu_e_luz()
	criar_terreno()
	criar_biblioteca()
	criar_paisagismo()
	criar_interior()
	criar_jogador()
	criar_instrucoes()
	criar_questionario()
	criar_fluxo_jogo()


# Compartilha materiais chapados entre as peças para economizar recursos.
func criar_materiais() -> void:
	for chave in Config.CORES:
		var material := StandardMaterial3D.new()
		material.albedo_color = Config.CORES[chave]
		material.roughness = 1.0
		material.metallic = 0.0
		material.metallic_specular = 0.0
		material.emission_enabled = false
		materiais[chave] = material


# Usa duas cores chapadas no céu, luz ambiente fraca e sol sem sombras.
func criar_ceu_e_luz() -> void:
	var shader_ceu := Shader.new()
	shader_ceu.code = Config.CEU_SHADER
	var material_ceu := ShaderMaterial.new()
	material_ceu.shader = shader_ceu
	material_ceu.set_shader_parameter("cor_topo", Config.CEU_TOPO)
	material_ceu.set_shader_parameter("cor_horizonte", Config.CEU_HORIZONTE)
	material_ceu.set_shader_parameter("altura_horizonte", Config.CEU_ALTURA_HORIZONTE)
	var ceu := Sky.new()
	ceu.sky_material = material_ceu
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = ceu
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Config.AMBIENTE_COR
	ambiente.ambient_light_energy = Config.AMBIENTE_ENERGIA
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Config.SOL_ROTACAO
	sol.light_color = Config.SOL_COR
	sol.light_energy = Config.SOL_ENERGIA
	sol.shadow_enabled = Config.SOL_SOMBRAS
	sol.light_cull_mask = Config.CAMADA_EXTERIOR
	add_child(sol)


# Monta o chão sólido, o caminho e as bordas baixas que delimitam o terreno.
func criar_terreno() -> void:
	criar_blocos(Config.TERRENO)


# Constrói a casca externa do prédio e sua entrada.
func criar_biblioteca() -> void:
	criar_blocos(Config.CASCA_BIBLIOTECA)
	criar_fachada()
	criar_porta()
	for x in Config.JANELAS_X:
		criar_janela(x)


# Forma a fachada com pilastras, frontão triangular e letreiro.
func criar_fachada() -> void:
	criar_blocos(Config.FACHADA)
	for x in Config.COLUNAS_X:
		for parte in Config.COLUNA_PARTES:
			criar_caixa("Pilastra", parte[0], parte[1] + Vector3(x, 0, 0), "pedra", false)
	var prisma := PrismMesh.new()
	prisma.size = Config.FRONTON_TAMANHO
	criar_malha("Frontao", prisma, Config.FRONTON_POSICAO, Config.FRONTON_COR)
	criar_placa(Config.PLACA_TITULO, Config.PLACA_POSICAO, Config.PLACA_ESCALA)
	criar_logo_fachada()


# Aplica a logo fornecida no frontão, mantendo a proporção e o acabamento fosco.
func criar_logo_fachada() -> void:
	var textura := load(Config.LOGO_ARQUIVO) as Texture2D
	if textura == null:
		push_warning("Não foi possível carregar a logo da fachada.")
		return
	var proporcao := textura.get_size()
	var fator := minf(Config.LOGO_LIMITE.x / proporcao.x, Config.LOGO_LIMITE.y / proporcao.y)
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var malha := QuadMesh.new()
	malha.size = proporcao * fator
	malha.material = material
	var logo := MeshInstance3D.new()
	logo.name = "LogoUnijorge"
	logo.mesh = malha
	logo.position = Config.LOGO_POSICAO
	logo.layers = Config.CAMADA_EXTERIOR
	logo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(logo)


# Cria os batentes e duas folhas já abertas, mantendo o vão central livre.
func criar_porta() -> void:
	criar_blocos(Config.PORTA_MOLDURA)
	for posicao in Config.PORTA_FOLHAS:
		criar_caixa("FolhaAberta", Config.PORTA_FOLHA_TAMANHO, posicao, "porta", true)
		var detalhe: Vector3 = Config.PORTA_DETALHE_OFFSET
		detalhe.x *= -signf(posicao.x)
		criar_caixa("Rebaixo", Config.PORTA_DETALHE_TAMANHO, posicao + detalhe, "janela", false)
		var macaneta: Vector3 = Config.PORTA_MACANETA_OFFSET
		macaneta.x = detalhe.x
		criar_caixa("Macaneta", Config.PORTA_MACANETA_TAMANHO, posicao + macaneta, "ouro", false)
	criar_placa(Config.ENTRADA_TEXTO, Config.ENTRADA_TEXTO_POSICAO, Config.ENTRADA_TEXTO_ESCALA)


# Desenha uma janela opaca estilizada com moldura, cruzeta e peitoril.
func criar_janela(x: float) -> void:
	for parte in Config.JANELA_PARTES:
		criar_caixa("Janela", parte[0], parte[1] + Vector3(x, 0, 0), parte[2], false)


# Usa árvores posicionadas no editor, com fallback procedural se a cena estiver vazia.
func criar_paisagismo() -> void:
	var paisagismo := Paisagismo.instantiate()
	add_child(paisagismo)
	if not paisagismo.tem_arvores_personalizadas():
		for posicao in Config.ARVORES:
			criar_arvore(posicao)
	for posicao in Config.BANCOS:
		for parte in Config.BANCO_PARTES:
			criar_caixa("Banco", parte[0], posicao + parte[1], parte[2], true)


# Combina um vaso e cilindros de poucos lados para formar uma árvore.
func criar_arvore(posicao: Vector3) -> void:
	criar_caixa("Vaso", Config.VASO_TAMANHO, posicao + Config.VASO_OFFSET, "rodape", true)
	criar_cilindro("Tronco", Config.TRONCO_RAIO, Config.TRONCO_RAIO, Config.TRONCO_ALTURA, posicao + Config.TRONCO_OFFSET, "tronco")
	for copa in Config.COPAS:
		criar_cilindro("Copa", copa[0], copa[1], copa[2], posicao + copa[3], copa[4])


# Instancia o jogador pelo script, olhando para a entrada no eixo -Z.
func criar_jogador() -> void:
	var jogador := Jogador.new()
	jogador.position = Config.JOGADOR_INICIO
	add_child(jogador)


# Delega a construção da recepção e das três salas a um script pequeno separado.
func criar_interior() -> void:
	var interior := Interior.new()
	interior.name = "Interior"
	interior.mundo = self
	add_child(interior)


# Exibe as instruções sem interceptar os cliques usados para capturar o mouse.
func criar_instrucoes() -> void:
	var camada := CanvasLayer.new()
	camada_instrucoes = camada
	add_child(camada)
	var painel := PanelContainer.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.position = Vector2(Config.HUD_MARGEM, Config.HUD_MARGEM)
	painel.custom_minimum_size = Config.HUD_TAMANHO
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Config.CORES["painel"]
	estilo.bg_color.a = Config.HUD_OPACIDADE
	estilo.content_margin_left = Config.HUD_MARGEM
	estilo.content_margin_right = Config.HUD_MARGEM
	estilo.content_margin_top = Config.HUD_MARGEM / 2.0
	estilo.content_margin_bottom = Config.HUD_MARGEM / 2.0
	painel.add_theme_stylebox_override("panel", estilo)
	camada.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", Config.HUD_ESPACO)
	painel.add_child(coluna)
	criar_texto_ui(coluna, Config.HUD_TITULO, Config.HUD_TITULO_FONTE)
	criar_texto_ui(coluna, Config.HUD_CONTROLES, Config.HUD_TEXTO_FONTE)


# Conecta os painéis das salas à interface de questões e ao placar da partida.
func criar_questionario() -> void:
	var questionario := Questionario.new()
	questionario.name = "Questionario"
	questionario.jogador = get_node("Jogador")
	questionario.camada_instrucoes = camada_instrucoes
	add_child(questionario)
	get_node("Interior").solicitar_questoes.connect(questionario.abrir_sala)
	questionario.progresso_alterado.connect(atualizar_paineis)
	questionario.atualizar_placar()


# Exibe nos terminais físicos o mesmo progresso mostrado pela interface.
func atualizar_paineis(sala: int, respondidas: int, total: int, acertos: int, concluida: bool) -> void:
	for terminal in get_tree().get_nodes_in_group("terminais_questoes"):
		if terminal.indice_sala == sala:
			terminal.atualizar_progresso(respondidas, total, acertos, concluida)


# Conecta menu inicial, pausa e tela final ao mundo e ao questionário.
func criar_fluxo_jogo() -> void:
	var fluxo := Fluxo.new()
	fluxo.name = "FluxoJogo"
	fluxo.jogador = get_node("Jogador")
	fluxo.questionario = get_node("Questionario")
	fluxo.camada_instrucoes = camada_instrucoes
	add_child(fluxo)


# Acrescenta uma linha de texto à ficha de controles.
func criar_texto_ui(pai: Node, texto: String, tamanho: int) -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_color_override("font_color", Config.CORES["hud"])
	rotulo.add_theme_font_size_override("font_size", tamanho)
	pai.add_child(rotulo)


# Converte uma lista de configuração em blocos do cenário.
func criar_blocos(blocos: Array) -> void:
	for bloco in blocos:
		criar_caixa(bloco[0], bloco[1], bloco[2], bloco[3], bloco[4])


# Cria uma caixa e, se necessário, um corpo estático com colisão equivalente.
func criar_caixa(titulo: String, tamanho: Vector3, posicao: Vector3, cor: String, solido: bool) -> MeshInstance3D:
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	var objeto := criar_malha(titulo, caixa, posicao, cor)
	if solido:
		var corpo := StaticBody3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamanho
		var colisao := CollisionShape3D.new()
		colisao.shape = forma
		objeto.add_child(corpo)
		corpo.add_child(colisao)
	return objeto


# Gera um cilindro facetado sem texturas.
func criar_cilindro(titulo: String, raio_base: float, raio_topo: float, altura: float, posicao: Vector3, cor: String) -> void:
	var cilindro := CylinderMesh.new()
	cilindro.bottom_radius = raio_base
	cilindro.top_radius = raio_topo
	cilindro.height = altura
	cilindro.radial_segments = Config.CILINDRO_SEGMENTOS
	cilindro.rings = 1
	criar_malha(titulo, cilindro, posicao, cor)


# Centraliza a criação das malhas e desliga a emissão de sombras nas peças.
func criar_malha(titulo: String, malha: Mesh, posicao: Vector3, cor: String) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	objeto.name = titulo
	objeto.mesh = malha
	objeto.material_override = materiais[cor]
	objeto.position = posicao
	objeto.layers = Config.CAMADA_EXTERIOR
	if cor == "piso":
		objeto.layers = Config.CAMADA_INTERIOR
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(objeto)
	return objeto


# Escreve na fachada com Label3D, sem fontes ou imagens importadas.
func criar_placa(texto: String, posicao: Vector3, escala_pixel: float) -> void:
	var placa := Label3D.new()
	placa.text = texto
	placa.position = posicao
	placa.pixel_size = escala_pixel
	placa.font_size = Config.FONTE_3D_TAMANHO
	placa.outline_size = 0
	placa.modulate = Config.CORES["texto"]
	add_child(placa)
