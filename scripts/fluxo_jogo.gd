extends CanvasLayer
## Menu inicial, pausa e tela final. Tudo é criado por código e usa a paleta central.

const Config = preload("res://scripts/configuracao.gd")
var jogador: CharacterBody3D
var questionario: CanvasLayer
var camada_instrucoes: CanvasLayer
var estado := "inicio"
var resultados: Array = []
var interface: Control
var painel: PanelContainer
var coluna_menu: VBoxContainer
var coluna_final: VBoxContainer
var titulo_menu: Label
var estado_menu: Label
var botao_jogar: Button
var resumo_total: Label
var resumo_detalhe: Label
var linhas_resultado: Array[Label] = []
var botoes_finais: BoxContainer
var camera_menu: Camera3D


# Cria a câmera de apresentação e abre o menu com o jogador bloqueado.
func _ready() -> void:
	layer = Config.MENU_CAMADA
	criar_camera_menu()
	criar_interface()
	questionario.partida_concluida.connect(mostrar_final)
	mostrar_menu(false)


# Apresenta a fachada com uma câmera leve, sem animações ou efeitos de tela.
func criar_camera_menu() -> void:
	camera_menu = Camera3D.new()
	camera_menu.name = "CameraApresentacao"
	camera_menu.position = Config.MENU_CAMERA_POSICAO
	camera_menu.fov = Config.MENU_CAMERA_FOV
	camera_menu.far = Config.JOGADOR_DISTANCIA_VISAO
	add_child(camera_menu)
	camera_menu.look_at(Config.MENU_CAMERA_ALVO)


# Monta um painel rolável para manter todos os botões acessíveis.
func criar_interface() -> void:
	interface = Control.new()
	add_child(interface)
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veu := ColorRect.new()
	veu.color = Config.CORES["painel"]
	veu.color.a = Config.MENU_FUNDO_OPACIDADE
	interface.add_child(veu)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel = PanelContainer.new()
	painel.add_theme_stylebox_override("panel", questionario.criar_estilo("painel", Config.MENU_PAINEL_MARGEM, Config.MENU_PAINEL_OPACIDADE))
	interface.add_child(painel)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	painel.add_child(rolagem)
	var conteudo := VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(conteudo)
	criar_menu(conteudo)
	criar_final(conteudo)
	interface.resized.connect(ajustar_tamanho)
	ajustar_tamanho()


# Mostra somente título, estado da pausa, os dois botões e as instruções abaixo.
func criar_menu(pai: Node) -> void:
	coluna_menu = VBoxContainer.new()
	coluna_menu.add_theme_constant_override("separation", Config.MENU_ESPACO)
	pai.add_child(coluna_menu)
	titulo_menu = questionario.criar_texto(coluna_menu, Config.MENU_TITULO, Config.MENU_TITULO_FONTE)
	estado_menu = questionario.criar_texto(coluna_menu, Config.MENU_PAUSA_TEXTO, Config.QUIZ_DETALHE_FONTE)
	botao_jogar = questionario.criar_botao("Jogar", jogar)
	coluna_menu.add_child(botao_jogar)
	coluna_menu.add_child(questionario.criar_botao("Sair", sair))
	questionario.criar_texto(coluna_menu, Config.MENU_CONTROLES, Config.QUIZ_DETALHE_FONTE)


# Cria a tela final com as três pontuações e ações explícitas para a próxima partida.
func criar_final(pai: Node) -> void:
	coluna_final = VBoxContainer.new()
	coluna_final.add_theme_constant_override("separation", Config.MENU_ESPACO)
	pai.add_child(coluna_final)
	questionario.criar_texto(coluna_final, Config.MENU_MARCA, Config.QUIZ_DETALHE_FONTE)
	questionario.criar_texto(coluna_final, Config.MENU_FINAL_TITULO, Config.MENU_TITULO_FONTE)
	questionario.criar_texto(coluna_final, Config.MENU_FINAL_MENSAGEM, Config.QUIZ_TEXTO_FONTE)
	resumo_total = questionario.criar_texto(coluna_final, "", Config.MENU_PLACAR_FONTE)
	resumo_detalhe = questionario.criar_texto(coluna_final, "", Config.QUIZ_DETALHE_FONTE)
	for i in range(Config.SALAS.size()):
		var cartao := PanelContainer.new()
		cartao.add_theme_stylebox_override("panel", questionario.criar_estilo("alternativa", Config.QUIZ_BOTAO_MARGEM))
		coluna_final.add_child(cartao)
		linhas_resultado.append(questionario.criar_texto(cartao, "", Config.QUIZ_TEXTO_FONTE))
	botoes_finais = BoxContainer.new()
	botoes_finais.add_theme_constant_override("separation", Config.QUIZ_ESPACO)
	coluna_final.add_child(botoes_finais)
	for dados in [["Explorar biblioteca", jogar], ["Jogar novamente", reiniciar], ["Sair", sair]]:
		var botao: Button = questionario.criar_botao(dados[0], dados[1])
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botoes_finais.add_child(botao)


# Mantém o menu dentro da janela e troca a posição para central na tela final.
func ajustar_tamanho() -> void:
	if painel == null:
		return
	var largura := Config.MENU_RESULTADO_LARGURA if estado == "final" else Config.MENU_LARGURA
	var altura := Config.MENU_ALTURA_MAX if estado == "final" else Config.MENU_ALTURA
	var tamanho := Vector2(minf(largura, interface.size.x - Config.MENU_MARGEM * 2.0), minf(altura, interface.size.y - Config.MENU_MARGEM * 2.0))
	painel.position = Vector2((interface.size.x - tamanho.x) / 2.0 if estado == "final" else Config.MENU_MARGEM, (interface.size.y - tamanho.y) / 2.0)
	painel.size = tamanho
	botoes_finais.vertical = interface.size.x < Config.QUIZ_LIMIAR_COLUNAS


# Abre o menu inicial ou uma pausa que preserva integralmente o progresso.
func mostrar_menu(pausa: bool) -> void:
	estado = "pausa" if pausa else "inicio"
	questionario.suspender()
	camada_instrucoes.hide()
	jogador.definir_interface(true)
	camera_menu.make_current()
	coluna_final.hide()
	coluna_menu.show()
	botao_jogar.text = "Continuar partida" if pausa else "Jogar"
	titulo_menu.text = Config.MENU_TITULO
	estado_menu.visible = pausa
	interface.show()
	ajustar_tamanho()
	botao_jogar.grab_focus()


# Retoma o mesmo mundo e a mesma pontuação, capturando o mouse somente ao jogar.
func jogar(capturar_mouse: bool = true) -> void:
	estado = "explorando"
	interface.hide()
	questionario.retomar_exploracao()
	camada_instrucoes.show()
	jogador.camera.make_current()
	jogador.definir_interface(false, capturar_mouse)


# Abre automaticamente o resumo quando o questionário conclui as três salas.
func mostrar_final(dados: Array) -> void:
	resultados = dados.duplicate(true)
	estado = "final"
	questionario.suspender()
	camada_instrucoes.hide()
	jogador.definir_interface(true)
	camera_menu.make_current()
	var acertos := 0
	var total := 0
	for i in range(resultados.size()):
		var sala: Dictionary = resultados[i]
		acertos += sala["acertos"]
		total += sala["total"]
		linhas_resultado[i].text = "%s  ·  %d / %d" % [sala["nome"].capitalize(), sala["acertos"], sala["total"]]
	resumo_total.text = "%d / %d acertos" % [acertos, total]
	resumo_detalhe.text = "Três salas concluídas · Pontuação desta partida"
	if total < Config.QUESTOES_POR_SALA * Config.SALAS.size():
		resumo_detalhe.text += "\nVersão com questões de exemplo"
	coluna_menu.hide()
	coluna_final.show()
	interface.show()
	ajustar_tamanho()
	botoes_finais.get_child(0).grab_focus()


# Reinicia a cena mínima, zerando questões, portas e posição em uma nova partida.
func reiniciar() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()


# Encerra a aplicação pelo botão Sair.
func sair() -> void:
	get_tree().quit()


# Tab abre uma pausa na exploração; Esc continua liberando o mouse normalmente.
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == Config.MENU_ATALHO:
		if estado == "explorando" and not questionario.modal.visible:
			mostrar_menu(true)
		elif estado == "pausa":
			jogar()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and estado != "explorando":
		if estado == "pausa":
			jogar(false)
		get_viewport().set_input_as_handled()
