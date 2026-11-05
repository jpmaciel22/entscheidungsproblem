extends AnimatableBody3D
## Porta com dobradiça à esquerda: a folha gira para dentro da sala ao clicar.

const Config = preload("res://scripts/configuracao.gd")
var assunto := ""
var materiais: Dictionary = {}
var aberta := false
var animando := false
var angulo_fechado := 0.0
var puxador: MeshInstance3D


# Cria folha, puxador e colisão móvel sem cena adicional.
func _ready() -> void:
	position += basis * Config.PORTA_SALA_DOBRADICA_OFFSET
	angulo_fechado = rotation.y
	criar_parte(Config.PORTA_SALA_TAMANHO, Config.PORTA_SALA_FOLHA_OFFSET, "porta")
	puxador = criar_parte(Config.PORTA_PUXADOR_TAMANHO, Config.PORTA_SALA_FOLHA_OFFSET + Config.PORTA_PUXADOR_OFFSET, "pedra")
	var forma := BoxShape3D.new()
	forma.size = Config.PORTA_SALA_TAMANHO
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position = Config.PORTA_SALA_FOLHA_OFFSET
	add_child(colisao)
	add_to_group("interativos")


# Gera uma das peças da porta com o mesmo acabamento fosco do interior.
func criar_parte(tamanho: Vector3, posicao: Vector3, cor: String) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	objeto.mesh = caixa
	objeto.material_override = materiais[cor]
	objeto.position = posicao
	objeto.layers = Config.CAMADA_INTERIOR
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(objeto)
	return objeto


# Informa qual sala será aberta pelo clique.
func obter_dica() -> String:
	return "Clique para abrir · " + assunto


# Aplica o único destaque quente apenas ao puxador da porta sob a mira.
func definir_foco(ativo: bool) -> void:
	puxador.material_override = materiais["interativo" if ativo else "pedra"]


# Gira folha, maçaneta e colisão juntas pela dobradiça e mantém a porta aberta.
func interagir() -> void:
	if aberta or animando:
		return
	aberta = true
	animando = true
	remove_from_group("interativos")
	definir_foco(false)
	var animacao := create_tween()
	animacao.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	animacao.set_trans(Tween.TRANS_SINE)
	animacao.set_ease(Tween.EASE_IN_OUT)
	animacao.tween_property(self, "rotation:y", angulo_fechado + Config.PORTA_SALA_ANGULO_ABERTURA, Config.PORTA_SALA_TEMPO)
	animacao.finished.connect(func() -> void: animando = false)
