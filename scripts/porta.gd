extends AnimatableBody3D
## Porta com dobradiça à esquerda: a folha gira para dentro da sala ao clicar.

const Config = preload("res://scripts/configuracao.gd")
const ModeloPorta = preload("res://assets/porta.glb")
signal abertura_iniciada(posicao: Vector3)
var assunto := ""
var materiais: Dictionary = {}
var aberta := false
var animando := false
var angulo_fechado := 0.0
var modelo_porta: Node3D


# Cria folha, puxador e colisão móvel sem cena adicional.
func _ready() -> void:
	position += basis * Config.PORTA_SALA_DOBRADICA_OFFSET
	angulo_fechado = rotation.y
	modelo_porta = ModeloPorta.instantiate() as Node3D
	modelo_porta.position = Config.PORTA_MODELO_OFFSET
	modelo_porta.rotation.y = Config.PORTA_MODELO_ROTACAO
	modelo_porta.scale = Config.PORTA_MODELO_ESCALA
	add_child(modelo_porta)
	configurar_malhas(modelo_porta)
	var forma := BoxShape3D.new()
	forma.size = Config.PORTA_SALA_TAMANHO
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position = Config.PORTA_SALA_FOLHA_OFFSET
	add_child(colisao)
	add_to_group("interativos")
	add_to_group("portas_salas")


# Mantém os materiais originais e ilumina a porta com as luzes internas.
func configurar_malhas(no: Node) -> void:
	if no is MeshInstance3D:
		no.layers = Config.CAMADA_INTERIOR
		no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for filho in no.get_children():
		configurar_malhas(filho)


# Informa qual sala será aberta pelo clique.
func obter_dica() -> String:
	return "Clique para abrir · " + assunto


# Aplica o único destaque quente apenas ao puxador da porta sob a mira.
func definir_foco(ativo: bool) -> void:
	# A dica e a mão indicam a interação, sem modificar o material do modelo.
	pass


# Gira folha, maçaneta e colisão juntas pela dobradiça e mantém a porta aberta.
func interagir() -> void:
	if aberta or animando:
		return
	aberta = true
	animando = true
	remove_from_group("interativos")
	definir_foco(false)
	abertura_iniciada.emit(global_position)
	var animacao := create_tween()
	animacao.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	animacao.set_trans(Tween.TRANS_SINE)
	animacao.set_ease(Tween.EASE_IN_OUT)
	animacao.tween_property(self, "rotation:y", angulo_fechado + Config.PORTA_SALA_ANGULO_ABERTURA, Config.PORTA_SALA_TEMPO)
	animacao.finished.connect(func() -> void: animando = false)
