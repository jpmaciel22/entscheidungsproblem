extends CanvasLayer
## Sobreposição de mãos e mira. O balanço afeta só o sprite, nunca a câmera.

const Config = preload("res://scripts/configuracao.gd")
const Mira = preload("res://scripts/mira.gd")
var jogador: CharacterBody3D
var raiz: Control
var mao: TextureRect
var mira: Control
var dica: Label
var texturas: Dictionary = {}
var estado := ""
var tempo_clique := 0.0
var fase := 0.0
var intensidade := 0.0


# Carrega os três sprites originais e monta a interface por código.
func _ready() -> void:
	for chave in Config.MAOS_ARQUIVOS:
		texturas[chave] = carregar_mao(chave)
	raiz = Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mao = TextureRect.new()
	mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mao.size = Config.MAO_TAMANHO
	raiz.add_child(mao)
	mira = Mira.new()
	raiz.add_child(mira)
	mira.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dica = Label.new()
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.size = Config.INTERACAO_DICA_TAMANHO
	dica.add_theme_font_size_override("font_size", Config.INTERACAO_DICA_FONTE)
	dica.add_theme_color_override("font_color", Config.CORES["interativo"])
	dica.add_theme_color_override("font_shadow_color", Config.CORES["painel"])
	raiz.add_child(dica)
	mudar_estado("idle")


# Usa um placeholder transparente se um dos arquivos não estiver disponível.
func carregar_mao(chave: String) -> Texture2D:
	var caminho: String = Config.MAOS_ARQUIVOS[chave]
	if ResourceLoader.exists(caminho):
		var textura := load(caminho) as Texture2D
		if textura != null:
			return textura
	var imagem := Image.create(Config.MAO_PLACEHOLDER_TAMANHO.x, Config.MAO_PLACEHOLDER_TAMANHO.y, false, Image.FORMAT_RGBA8)
	var transparente: Color = Config.CORES["hud"]
	transparente.a = 0.0
	imagem.fill(transparente)
	imagem.fill_rect(Config.MAO_PLACEHOLDER_BRACO, Config.CORES["estante"])
	imagem.fill_rect(Config.MAO_PLACEHOLDER_PALMA, Config.CORES["livro_3"])
	if chave == "point":
		imagem.fill_rect(Config.MAO_PLACEHOLDER_DEDO, Config.CORES["livro_3"])
	return ImageTexture.create_from_image(imagem)


# Atualiza a mira, a dica e o balanço conforme a velocidade real do corpo.
func _process(delta: float) -> void:
	if jogador.get("interface_aberta"):
		raiz.hide()
		tempo_clique = 0.0
		intensidade = 0.0
		return
	raiz.show()
	var capturado := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var alvo: Node = jogador.get("alvo_interativo")
	var apontando := capturado and is_instance_valid(alvo)
	mira.visible = capturado
	mira.set("interativo", apontando)
	dica.visible = apontando
	dica.text = alvo.obter_dica() if apontando else ""
	dica.position = raiz.size / 2.0 + Config.INTERACAO_DICA_OFFSET
	if not capturado:
		tempo_clique = 0.0
	tempo_clique = maxf(tempo_clique - delta, 0.0)
	mudar_estado("click" if tempo_clique > 0.0 else ("point" if apontando else "idle"))
	var velocidade := jogador.get_real_velocity()
	var velocidade_horizontal := Vector2(velocidade.x, velocidade.z).length()
	var andando := capturado and jogador.is_on_floor() and velocidade_horizontal > 0.1
	var destino := clampf(velocidade_horizontal / Config.JOGADOR_VELOCIDADE, 0.0, 1.0) if andando else 0.0
	intensidade = move_toward(intensidade, destino, Config.MAO_BALANCO_SUAVIDADE * delta)
	fase += delta * Config.MAO_BALANCO_FREQUENCIA * destino
	var balanco := Vector2(sin(fase / 2.0), sin(fase)) * Config.MAO_BALANCO_AMPLITUDE * intensidade
	var clique := Vector2(0, Config.MAO_CLIQUE_DESLOCAMENTO if tempo_clique > 0.0 else 0.0)
	mao.position = raiz.size - Config.MAO_TAMANHO + Config.MAO_OFFSET + balanco + clique


# Troca de textura apenas quando o estado muda.
func mudar_estado(novo_estado: String) -> void:
	if estado != novo_estado:
		estado = novo_estado
		mao.texture = texturas[estado]


# Mantém o dedo pressionado por aproximadamente quinze centésimos de segundo.
func animar_clique() -> void:
	tempo_clique = Config.MAO_CLIQUE_DURACAO
	mudar_estado("click")
