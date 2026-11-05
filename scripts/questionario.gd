extends CanvasLayer
## Questões, feedback, retomada e resultados. A interface inteira nasce por código.

signal progresso_alterado(sala: int, respondidas: int, total: int, acertos: int, concluida: bool)
signal partida_concluida(resultados: Array)
const Config = preload("res://scripts/configuracao.gd")
const Banco = preload("res://scripts/banco_questoes.gd")
var jogador: CharacterBody3D
var camada_instrucoes: CanvasLayer
var salas: Array = []
var sala_atual := -1
var interface: Control
var modal: Control
var painel: PanelContainer
var placar: PanelContainer
var linhas_placar: Array[Label] = []
var titulo: Label
var progresso: Label
var barra: ProgressBar
var rolagem: ScrollContainer
var conteudo: VBoxContainer
var enunciado: Label
var referencia: Label
var linha_pergunta: BoxContainer
var moldura_imagem: PanelContainer
var imagem: TextureRect
var placeholder: Label
var alternativas: VBoxContainer
var botoes: Array[Button] = []
var feedback_painel: PanelContainer
var feedback: Label
var resultado: Label
var proxima: Button
var final_notificado := false


# Carrega os três bancos, cria a interface e começa com o placar discreto.
func _ready() -> void:
	layer = Config.QUIZ_CAMADA
	for caminho in Config.QUESTOES_ARQUIVOS:
		var banco := Banco.carregar(caminho)
		salas.append({"questoes": banco["questoes"], "erro": banco["erro"], "indice": 0,
			"acertos": 0, "respostas": [], "concluida": false})
	criar_interface()
	modal.hide()
	atualizar_placar()


# Monta a camada de fundo, o painel e a área rolável para janelas menores.
func criar_interface() -> void:
	interface = Control.new()
	interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(interface)
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = Control.new()
	interface.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veu := ColorRect.new()
	veu.color = Config.CORES["painel"]
	veu.color.a = Config.QUIZ_VEU_OPACIDADE
	modal.add_child(veu)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel = PanelContainer.new()
	painel.add_theme_stylebox_override("panel", criar_estilo("painel", Config.QUIZ_PAINEL_MARGEM, Config.QUIZ_PAINEL_OPACIDADE))
	modal.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", Config.QUIZ_ESPACO)
	painel.add_child(coluna)
	var cabecalho := HBoxContainer.new()
	coluna.add_child(cabecalho)
	titulo = criar_texto(cabecalho, "", Config.QUIZ_TITULO_FONTE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var voltar := criar_botao("Voltar à biblioteca", fechar)
	voltar.custom_minimum_size.x = Config.QUIZ_VOLTAR_LARGURA
	cabecalho.add_child(voltar)
	progresso = criar_texto(coluna, "", Config.QUIZ_DETALHE_FONTE)
	barra = ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size.y = Config.QUIZ_BARRA_ALTURA
	barra.add_theme_stylebox_override("background", criar_estilo("alternativa", 0))
	barra.add_theme_stylebox_override("fill", criar_estilo("alternativa_selecionada", 0))
	coluna.add_child(barra)
	rolagem = ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	conteudo = VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", Config.QUIZ_ESPACO)
	rolagem.add_child(conteudo)
	enunciado = criar_texto(conteudo, "", Config.QUIZ_TEXTO_FONTE)
	referencia = criar_texto(conteudo, "", Config.QUIZ_DETALHE_FONTE)
	referencia.add_theme_color_override("font_color", Config.CORES["livro_3"])
	criar_pergunta()
	feedback_painel = PanelContainer.new()
	conteudo.add_child(feedback_painel)
	feedback = criar_texto(feedback_painel, "", Config.QUIZ_TEXTO_FONTE)
	resultado = criar_texto(conteudo, "", Config.QUIZ_TEXTO_FONTE)
	proxima = criar_botao("Próxima questão", avancar)
	coluna.add_child(proxima)
	criar_placar()
	interface.resized.connect(ajustar_tamanho)
	ajustar_tamanho()


# Coloca gráfico e alternativas lado a lado, ou empilhados em janela estreita.
func criar_pergunta() -> void:
	linha_pergunta = BoxContainer.new()
	linha_pergunta.add_theme_constant_override("separation", Config.QUIZ_ESPACO)
	conteudo.add_child(linha_pergunta)
	moldura_imagem = PanelContainer.new()
	moldura_imagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moldura_imagem.size_flags_stretch_ratio = Config.QUIZ_IMAGEM_PROPORCAO
	moldura_imagem.add_theme_stylebox_override("panel", criar_estilo("placa_fundo", 0))
	linha_pergunta.add_child(moldura_imagem)
	imagem = TextureRect.new()
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.custom_minimum_size.y = Config.QUIZ_IMAGEM_ALTURA
	moldura_imagem.add_child(imagem)
	placeholder = criar_texto(moldura_imagem, "", Config.QUIZ_DETALHE_FONTE)
	placeholder.custom_minimum_size.y = Config.QUIZ_IMAGEM_ALTURA
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Config.CORES["placa_texto"])
	alternativas = VBoxContainer.new()
	alternativas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alternativas.size_flags_stretch_ratio = Config.QUIZ_RESPOSTAS_PROPORCAO
	alternativas.add_theme_constant_override("separation", Config.QUIZ_ESPACO)
	linha_pergunta.add_child(alternativas)
	for indice in range(4):
		var botao := criar_botao("", responder.bind(indice))
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		alternativas.add_child(botao)
		botoes.append(botao)


# Cria o resumo das três salas durante a exploração.
func criar_placar() -> void:
	placar = PanelContainer.new()
	placar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placar.add_theme_stylebox_override("panel", criar_estilo("painel", Config.QUIZ_BOTAO_MARGEM, Config.HUD_OPACIDADE))
	interface.add_child(placar)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placar.add_child(coluna)
	criar_texto(coluna, Config.PLACAR_TITULO, Config.QUIZ_DETALHE_FONTE)
	for i in range(salas.size()):
		linhas_placar.append(criar_texto(coluna, "", Config.QUIZ_DETALHE_FONTE))


# Ajusta os limites da janela sem cortar conteúdo: o miolo pode rolar.
func ajustar_tamanho() -> void:
	if painel == null or placar == null:
		return
	var tamanho := Vector2(minf(Config.QUIZ_LARGURA_MAX, interface.size.x - Config.QUIZ_MARGEM * 2.0), interface.size.y - Config.QUIZ_MARGEM * 2.0)
	painel.position = (interface.size - tamanho) / 2.0
	painel.size = tamanho
	linha_pergunta.vertical = interface.size.x < Config.QUIZ_LIMIAR_COLUNAS
	placar.position = Vector2(Config.PLACAR_MARGEM, interface.size.y - Config.PLACAR_ALTURA - Config.PLACAR_MARGEM)
	placar.size = Vector2(Config.PLACAR_LARGURA, Config.PLACAR_ALTURA)


# Abre o banco selecionado, preservando respostas e feedback de tentativas em curso.
func abrir_sala(indice: int) -> void:
	if not visible or modal.visible or indice < 0 or indice >= salas.size():
		return
	sala_atual = indice
	modal.show()
	placar.hide()
	camada_instrucoes.hide()
	jogador.definir_interface(true)
	titulo.text = Config.SALAS[indice]["nome"]
	rolagem.scroll_vertical = 0
	var estado: Dictionary = salas[indice]
	if not estado["erro"].is_empty():
		mostrar_erro(estado["erro"])
	elif estado["concluida"]:
		mostrar_resultado()
	else:
		mostrar_questao()
	get_viewport().set_input_as_handled()


# Exibe uma questão e restaura feedback se ela já tiver sido respondida.
func mostrar_questao() -> void:
	var estado: Dictionary = salas[sala_atual]
	var indice: int = estado["indice"]
	var total: int = estado["questoes"].size()
	var questao: Dictionary = estado["questoes"][indice]
	progresso.text = "Questão %d de %d  ·  Acertos: %d/%d" % [indice + 1, total, estado["acertos"], total]
	if total < Config.QUESTOES_POR_SALA:
		progresso.text += "  ·  Versão com questões de exemplo"
	barra.max_value = total
	barra.value = estado["respostas"].size()
	barra.show()
	enunciado.text = questao["enunciado"]
	enunciado.show()
	referencia.text = questao.get("fonte", "")
	referencia.visible = not referencia.text.is_empty()
	linha_pergunta.show()
	resultado.hide()
	feedback_painel.hide()
	proxima.hide()
	carregar_imagem(questao["imagem"])
	for i in range(botoes.size()):
		var botao := botoes[i]
		botao.text = "%s  ·  %s" % [char(65 + i), questao["alternativas"][i]]
		botao.disabled = false
		botao.add_theme_stylebox_override("disabled", criar_estilo("alternativa", Config.QUIZ_BOTAO_MARGEM))
	if estado["respostas"].size() > indice:
		mostrar_feedback(estado["respostas"][indice])
	rolagem.scroll_vertical = 0
	botoes[0].grab_focus()


# Carrega o PNG opcional; a ausência vira um placeholder em vez de um erro fatal.
func carregar_imagem(caminho: String) -> void:
	imagem.texture = null
	moldura_imagem.visible = not caminho.is_empty()
	if caminho.is_empty():
		return
	if ResourceLoader.exists(caminho):
		imagem.texture = load(caminho) as Texture2D
	imagem.visible = imagem.texture != null
	placeholder.visible = imagem.texture == null
	placeholder.text = "Imagem indisponível\n\nO arquivo de gráfico não foi encontrado."
	if imagem.texture == null:
		placeholder.text += "\n" + caminho.get_file()


# Registra uma única resposta por questão, mesmo com cliques repetidos.
func responder(indice: int) -> void:
	if not modal.visible or sala_atual < 0 or indice < 0 or indice >= 4:
		return
	var estado: Dictionary = salas[sala_atual]
	if estado["concluida"] or not estado["erro"].is_empty() or estado["respostas"].size() > estado["indice"]:
		return
	var questao: Dictionary = estado["questoes"][estado["indice"]]
	estado["respostas"].append(indice)
	if indice == questao["indice_correto"]:
		estado["acertos"] += 1
	mostrar_feedback(indice)
	atualizar_placar()


# Bloqueia as opções e explica o resultado com texto e contorno de cor discreta.
func mostrar_feedback(escolha: int) -> void:
	var estado: Dictionary = salas[sala_atual]
	var questao: Dictionary = estado["questoes"][estado["indice"]]
	var correto: int = questao["indice_correto"]
	var acertou := escolha == correto
	for i in range(botoes.size()):
		botoes[i].disabled = true
		var estilo := criar_estilo("alternativa_selecionada" if i == escolha else "alternativa", Config.QUIZ_BOTAO_MARGEM)
		if i == correto or i == escolha:
			estilo.set_border_width_all(Config.QUIZ_BORDA)
			estilo.border_color = Config.CORES["acerto" if i == correto else "erro"]
		botoes[i].add_theme_stylebox_override("disabled", estilo)
	feedback.text = "Resposta correta!" if acertou else "Resposta incorreta. A alternativa correta é %s." % char(65 + correto)
	feedback.text += "\n" + questao["explicacao"]
	var estilo := criar_estilo("alternativa", Config.QUIZ_BOTAO_MARGEM)
	estilo.border_width_left = Config.QUIZ_BORDA
	estilo.border_color = Config.CORES["acerto" if acertou else "erro"]
	feedback_painel.add_theme_stylebox_override("panel", estilo)
	feedback_painel.show()
	proxima.text = "Ver resultado da sala" if estado["indice"] == estado["questoes"].size() - 1 else "Próxima questão"
	proxima.show()
	proxima.grab_focus()
	barra.value = estado["respostas"].size()
	progresso.text = "Questão %d de %d  ·  Acertos: %d/%d" % [estado["indice"] + 1, estado["questoes"].size(), estado["acertos"], estado["questoes"].size()]


# Avança apenas depois de uma resposta; o último avanço encerra a sala.
func avancar() -> void:
	if not modal.visible or sala_atual < 0:
		return
	var estado: Dictionary = salas[sala_atual]
	if estado["concluida"] or estado["respostas"].size() <= estado["indice"]:
		return
	estado["indice"] += 1
	if estado["indice"] >= estado["questoes"].size():
		estado["concluida"] = true
		mostrar_resultado()
	else:
		mostrar_questao()
	atualizar_placar()


# Mostra a pontuação real da sala e um resumo das três sem encerrar a exploração.
func mostrar_resultado() -> void:
	referencia.hide()
	var estado: Dictionary = salas[sala_atual]
	enunciado.text = "Sala concluída! Você acertou %d de %d questões." % [estado["acertos"], estado["questoes"].size()]
	enunciado.show()
	linha_pergunta.hide()
	feedback_painel.hide()
	proxima.hide()
	progresso.text = "Resultado registrado nesta partida"
	barra.value = barra.max_value
	resultado.text = "PONTUAÇÃO DAS SALAS\n\n"
	for i in range(salas.size()):
		resultado.text += resumo_sala(i) + "\n"
	resultado.text += "\nUse ‘Voltar à biblioteca’ para explorar as outras salas."
	resultado.show()
	rolagem.scroll_vertical = 0


# Explica bancos inválidos sem travar o jogo ou oferecer questões incompletas.
func mostrar_erro(mensagem: String) -> void:
	referencia.hide()
	progresso.text = "Não foi possível carregar esta sala"
	enunciado.text = mensagem
	enunciado.show()
	barra.hide()
	linha_pergunta.hide()
	feedback_painel.hide()
	resultado.hide()
	proxima.hide()


# Fecha sem perder progresso; Esc mantém o cursor livre, e o botão retoma o jogo.
func fechar(capturar_mouse: bool = true) -> void:
	modal.hide()
	placar.show()
	camada_instrucoes.show()
	jogador.definir_interface(false, capturar_mouse)
	sala_atual = -1


# Trata Esc antes do jogador e impede que o mesmo evento volte a capturar o mouse.
func _input(event: InputEvent) -> void:
	if visible and modal.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		fechar(false)
		get_viewport().set_input_as_handled()


# Atualiza tanto a lista de pontuações quanto os painéis físicos de cada sala.
func atualizar_placar() -> void:
	for i in range(salas.size()):
		linhas_placar[i].text = resumo_sala(i)
		var estado: Dictionary = salas[i]
		progresso_alterado.emit(i, estado["respostas"].size(), estado["questoes"].size(), estado["acertos"], estado["concluida"])
	if not final_notificado and todas_concluidas():
		final_notificado = true
		partida_concluida.emit(obter_resultados())


# Só considera a partida concluída quando as três salas válidas terminaram.
func todas_concluidas() -> bool:
	if salas.size() != Config.SALAS.size():
		return false
	for estado in salas:
		if not estado["concluida"] or not estado["erro"].is_empty():
			return false
	return true


# Retorna um resumo independente para a tela final, sem expor respostas mutáveis.
func obter_resultados() -> Array:
	var resultados: Array = []
	for i in range(salas.size()):
		resultados.append({"nome": Config.SALAS[i]["nome"], "acertos": salas[i]["acertos"],
			"total": salas[i]["questoes"].size(), "concluida": salas[i]["concluida"]})
	return resultados


# Suspende a UI sem reativar o jogador por trás do menu ou da tela final.
func suspender() -> void:
	modal.hide()
	sala_atual = -1
	hide()


# Retorna o placar à exploração sem apagar nenhuma resposta da partida.
func retomar_exploracao() -> void:
	modal.hide()
	placar.show()
	show()


# Distingue salas não iniciadas, em andamento, concluídas e indisponíveis.
func resumo_sala(indice: int) -> String:
	var estado: Dictionary = salas[indice]
	var nome: String = Config.SALAS[indice]["nome"].capitalize()
	if not estado["erro"].is_empty():
		return nome + " · indisponível"
	if estado["concluida"]:
		return "%s · %d/%d" % [nome, estado["acertos"], estado["questoes"].size()]
	if not estado["respostas"].is_empty():
		return "%s · %d/%d respondidas" % [nome, estado["respostas"].size(), estado["questoes"].size()]
	return nome + " · não iniciada"


# Cria texto com quebra automática e as cores exatas da interface.
func criar_texto(pai: Node, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", Config.CORES["hud"])
	pai.add_child(rotulo)
	return rotulo


# Cria um botão legível com estilos para repouso, foco, hover e clique.
func criar_botao(texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.custom_minimum_size.y = Config.QUIZ_BOTAO_ALTURA
	botao.add_theme_font_size_override("font_size", Config.QUIZ_TEXTO_FONTE)
	for nome in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		botao.add_theme_color_override(nome, Config.CORES["hud"])
	for estado in ["normal", "disabled"]:
		botao.add_theme_stylebox_override(estado, criar_estilo("alternativa", Config.QUIZ_BOTAO_MARGEM))
	botao.add_theme_stylebox_override("hover", criar_estilo("alternativa_hover", Config.QUIZ_BOTAO_MARGEM))
	botao.add_theme_stylebox_override("pressed", criar_estilo("alternativa_selecionada", Config.QUIZ_BOTAO_MARGEM))
	botao.add_theme_stylebox_override("hover_pressed", criar_estilo("alternativa_selecionada", Config.QUIZ_BOTAO_MARGEM))
	var foco := criar_estilo("alternativa_hover", 0, 0.0)
	foco.set_border_width_all(Config.QUIZ_FOCO_BORDA)
	foco.border_color = Config.CORES["livro_1"]
	botao.add_theme_stylebox_override("focus", foco)
	botao.pressed.connect(acao)
	return botao


# Gera estilos chapados e reutiliza somente cores da configuração central.
func criar_estilo(cor: String, margem: int, opacidade: float = 1.0) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Config.CORES[cor]
	estilo.bg_color.a = opacidade
	estilo.content_margin_left = margem
	estilo.content_margin_right = margem
	estilo.content_margin_top = margem / 2.0
	estilo.content_margin_bottom = margem / 2.0
	estilo.set_corner_radius_all(Config.QUIZ_RAIO)
	return estilo
