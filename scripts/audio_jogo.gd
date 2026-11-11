extends Node
## Trilha e efeitos carregados uma vez, com passos ligados ao movimento real.

const Config = preload("res://scripts/configuracao.gd")
var jogador: CharacterBody3D
var questionario: CanvasLayer
var sons: Dictionary = {}
var musica: AudioStreamPlayer
var passos: AudioStreamPlayer
var resposta: AudioStreamPlayer
var porta: AudioStreamPlayer3D
var janela_ativa := true


# Prepara os arquivos, configura os loops e inicia a trilha suavemente.
func _ready() -> void:
	for chave in Config.AUDIO_ARQUIVOS:
		sons[chave] = carregar_som(chave)
	configurar_loop(sons["musica"])
	configurar_loop(sons["passos"])
	musica = criar_tocador("Musica", sons["musica"], Config.AUDIO_MUSICA_INICIO_DB)
	passos = criar_tocador("Passos", sons["passos"], Config.AUDIO_PASSOS_DB)
	resposta = criar_tocador("Resposta", null, Config.AUDIO_RESPOSTA_DB)
	porta = AudioStreamPlayer3D.new()
	porta.name = "SomPorta"
	porta.stream = sons["porta"]
	porta.volume_db = Config.AUDIO_PORTA_DB
	porta.max_distance = Config.AUDIO_PORTA_DISTANCIA
	porta.unit_size = Config.AUDIO_PORTA_UNIDADE
	add_child(porta)
	if musica.stream != null:
		musica.play()


# Copia o recurso e corta só o silêncio excedente, sem reescrever o WAV original.
func carregar_som(chave: String) -> AudioStreamWAV:
	var caminho: String = Config.AUDIO_ARQUIVOS[chave]
	if not ResourceLoader.exists(caminho):
		push_warning("Som indisponível: " + caminho)
		return null
	var original := load(caminho) as AudioStreamWAV
	if original == null:
		push_warning("O som precisa estar em WAV: " + caminho)
		return null
	var som := original.duplicate() as AudioStreamWAV
	som.loop_mode = AudioStreamWAV.LOOP_DISABLED
	if Config.AUDIO_RECORTES.has(chave):
		if som.format != AudioStreamWAV.FORMAT_8_BITS and som.format != AudioStreamWAV.FORMAT_16_BITS:
			push_warning("Recorte ignorado: importe o efeito sem compressão: " + caminho)
			return som
		var trecho: Vector2 = Config.AUDIO_RECORTES[chave]
		var bytes_por_quadro: int = (2 if som.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if som.stereo else 1)
		var inicio := roundi(trecho.x * som.mix_rate) * bytes_por_quadro
		var fim := mini(roundi(trecho.y * som.mix_rate) * bytes_por_quadro, som.data.size())
		if fim > inicio:
			som.data = som.data.slice(inicio, fim)
	return som


# Define os limites em quadros de amostras, respeitando áudio mono ou estéreo.
func configurar_loop(som: AudioStreamWAV) -> void:
	if som == null:
		return
	som.loop_begin = 0
	som.loop_end = roundi(som.get_length() * som.mix_rate)
	som.loop_mode = AudioStreamWAV.LOOP_FORWARD


# Cria um canal simples sem efeitos ou processamento de reverberação.
func criar_tocador(nome: String, som: AudioStream, volume: float) -> AudioStreamPlayer:
	var tocador := AudioStreamPlayer.new()
	tocador.name = nome
	tocador.stream = som
	tocador.volume_db = volume
	add_child(tocador)
	return tocador


# Só mantém os passos ao caminhar de verdade, apoiado e com controle da câmera.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(jogador):
		return
	var velocidade := jogador.get_real_velocity()
	var horizontal := Vector2(velocidade.x, velocidade.z).length()
	var andando: bool = janela_ativa and not jogador.get("interface_aberta") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and jogador.is_on_floor() and horizontal > Config.AUDIO_PASSOS_VELOCIDADE_MIN
	if andando and passos.stream != null:
		passos.pitch_scale = clampf(horizontal / Config.JOGADOR_VELOCIDADE, Config.AUDIO_PASSOS_RITMO_MIN, Config.AUDIO_PASSOS_RITMO_MAX)
		if not passos.playing:
			passos.play()
	elif passos.playing:
		passos.stop()


# Reduz a trilha na leitura e nos menus, sem reiniciar sua posição a cada tela.
func _process(delta: float) -> void:
	var destino := Config.AUDIO_MUSICA_DB
	if is_instance_valid(jogador) and jogador.get("interface_aberta"):
		destino = Config.AUDIO_MUSICA_MENU_DB
	if is_instance_valid(questionario) and questionario.visible and questionario.modal.visible:
		destino = Config.AUDIO_MUSICA_QUESTOES_DB
	musica.volume_db = move_toward(musica.volume_db, destino, Config.AUDIO_MUSICA_FADE_DB_SEGUNDO * delta)


# Posiciona a abertura na porta clicada para o som acompanhar sua localização.
func tocar_porta(posicao: Vector3) -> void:
	if porta.stream != null and janela_ativa:
		porta.global_position = posicao
		porta.play()


# Toca somente para uma resposta nova; reabrir a questão não repete o efeito.
func tocar_resposta(correta: bool) -> void:
	resposta.stream = sons["acertou" if correta else "errou"]
	if resposta.stream != null and janela_ativa:
		resposta.play()


# Suspende o áudio ao trocar de janela e retoma a trilha do mesmo ponto.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT and what != NOTIFICATION_APPLICATION_FOCUS_IN:
		return
	janela_ativa = what == NOTIFICATION_APPLICATION_FOCUS_IN
	if is_instance_valid(musica):
		musica.stream_paused = not janela_ativa
	if is_instance_valid(resposta):
		resposta.stream_paused = not janela_ativa
	if is_instance_valid(porta):
		porta.stream_paused = not janela_ativa
	if is_instance_valid(passos) and not janela_ativa:
		passos.stop()
