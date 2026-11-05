extends CharacterBody3D
## Jogador criado por código, com cápsula física e câmera em primeira pessoa.

const Config = preload("res://scripts/configuracao.gd")
const Maos = preload("res://scripts/maos.gd")
var camera: Camera3D
var inclinacao := 0.0
var raio: RayCast3D
var alvo_interativo: Node
var interface_maos: CanvasLayer
var interface_aberta := false


# Monta o jogador sem precisar de nós ou configurações manuais no editor.
func _ready() -> void:
	name = "Jogador"
	floor_snap_length = Config.JOGADOR_AJUSTE_CHAO
	criar_controles()
	criar_corpo()
	criar_camera()
	criar_interacao()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Registra WASD pela posição física das teclas.
func criar_controles() -> void:
	for acao in Config.ACOES:
		if not InputMap.has_action(acao):
			InputMap.add_action(acao)
			var tecla := InputEventKey.new()
			tecla.physical_keycode = Config.ACOES[acao]
			InputMap.action_add_event(acao, tecla)


# Faz a origem do jogador coincidir com seus pés.
func criar_corpo() -> void:
	var forma := CapsuleShape3D.new()
	forma.radius = Config.JOGADOR_RAIO
	forma.height = Config.JOGADOR_ALTURA
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position.y = Config.JOGADOR_ALTURA / 2.0
	add_child(colisao)


# Coloca os olhos na altura humana e limita a distância de renderização.
func criar_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position.y = Config.JOGADOR_OLHOS
	camera.fov = Config.JOGADOR_FOV
	camera.far = Config.JOGADOR_DISTANCIA_VISAO
	add_child(camera)
	camera.make_current()


# Anexa o raio ao centro da câmera e cria as mãos e a mira sobrepostas.
func criar_interacao() -> void:
	raio = RayCast3D.new()
	raio.name = "RaioInteracao"
	raio.target_position = Vector3(0, 0, -Config.INTERACAO_DISTANCIA)
	raio.enabled = true
	raio.add_exception(self)
	camera.add_child(raio)
	interface_maos = Maos.new()
	interface_maos.name = "MaosEMira"
	interface_maos.jogador = self
	add_child(interface_maos)


# Só seleciona o primeiro corpo atingido, impedindo interações através de paredes.
func atualizar_alvo() -> void:
	var novo_alvo: Node = null
	if not interface_aberta and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		raio.force_raycast_update()
		if raio.is_colliding():
			var corpo: Node = raio.get_collider()
			if corpo.is_in_group("interativos"):
				novo_alvo = corpo
	if novo_alvo == alvo_interativo:
		return
	if is_instance_valid(alvo_interativo):
		alvo_interativo.definir_foco(false)
	alvo_interativo = novo_alvo
	if is_instance_valid(alvo_interativo):
		alvo_interativo.definir_foco(true)


# Esc solta o mouse; um clique retoma a captura e o movimento da câmera.
func _unhandled_input(event: InputEvent) -> void:
	if interface_aberta:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		atualizar_alvo()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		atualizar_alvo()
		interface_maos.animar_clique()
		if is_instance_valid(alvo_interativo):
			alvo_interativo.interagir()
			atualizar_alvo()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * Config.JOGADOR_SENSIBILIDADE)
		var limite := deg_to_rad(Config.JOGADOR_LIMITE_OLHAR)
		inclinacao = clampf(inclinacao - event.relative.y * Config.JOGADOR_SENSIBILIDADE, -limite, limite)
		camera.rotation.x = inclinacao


# Move com gravidade e colisões, sem aumentar a velocidade nas diagonais.
func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if not interface_aberta and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		entrada = Input.get_vector("andar_esquerda", "andar_direita", "andar_frente", "andar_tras")
	var direcao := global_transform.basis * Vector3(entrada.x, 0, entrada.y)
	velocity.x = move_toward(velocity.x, direcao.x * Config.JOGADOR_VELOCIDADE, Config.JOGADOR_ACELERACAO * delta)
	velocity.z = move_toward(velocity.z, direcao.z * Config.JOGADOR_VELOCIDADE, Config.JOGADOR_ACELERACAO * delta)
	if not is_on_floor():
		velocity.y -= Config.JOGADOR_GRAVIDADE * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	atualizar_alvo()
	if position.y < Config.JOGADOR_RETORNO_Y:
		position = Config.JOGADOR_INICIO
		velocity = Vector3.ZERO


# Libera o cursor quando a janela perde o foco.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Bloqueia movimento e olhar durante as questões e libera o cursor para a UI.
func definir_interface(aberta: bool, capturar_mouse: bool = true) -> void:
	interface_aberta = aberta
	velocity.x = 0.0
	velocity.z = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aberta or not capturar_mouse else Input.MOUSE_MODE_CAPTURED
	atualizar_alvo()
