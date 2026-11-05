extends StaticBody3D
## Painel físico que abre o questionário da sala ao ser clicado pela mira.

signal solicitar_questoes(indice: int)
const Config = preload("res://scripts/configuracao.gd")
var indice_sala := 0
var materiais: Dictionary = {}
var tela: MeshInstance3D
var status: Label3D
var concluida := false
var iniciada := false


# Monta um painel simples com suporte, colisão e duas linhas de texto.
func _ready() -> void:
	criar_parte(Config.TERMINAL_TAMANHO, Vector3.ZERO, "estante")
	tela = criar_parte(Config.TERMINAL_TELA_TAMANHO, Config.TERMINAL_TELA_OFFSET, "placa_fundo")
	criar_parte(Config.TERMINAL_SUPORTE_TAMANHO, Config.TERMINAL_SUPORTE_OFFSET, "estante")
	criar_parte(Config.TERMINAL_BASE_TAMANHO, Config.TERMINAL_BASE_OFFSET, "estante")
	criar_texto("QUESTÕES", Config.TERMINAL_TEXTO_OFFSET, Config.TERMINAL_TEXTO_ESCALA)
	status = criar_texto("CLIQUE PARA COMEÇAR", Config.TERMINAL_STATUS_OFFSET, Config.TERMINAL_STATUS_ESCALA)
	var forma := BoxShape3D.new()
	forma.size = Config.TERMINAL_TAMANHO
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	add_child(colisao)
	add_to_group("interativos")
	add_to_group("terminais_questoes")


# Cria uma peça fosca na camada do interior.
func criar_parte(tamanho: Vector3, posicao: Vector3, cor: String) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	objeto.mesh = caixa
	objeto.position = posicao
	objeto.material_override = materiais[cor]
	objeto.layers = Config.CAMADA_INTERIOR
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(objeto)
	return objeto


# Mantém o texto legível sem emitir luz ou importar imagens para o painel.
func criar_texto(texto: String, posicao: Vector3, escala: float) -> Label3D:
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.position = posicao
	rotulo.pixel_size = escala
	rotulo.font_size = Config.FONTE_3D_TAMANHO
	rotulo.modulate = Config.CORES["placa_texto"]
	rotulo.outline_size = 0
	rotulo.layers = Config.CAMADA_INTERIOR
	add_child(rotulo)
	return rotulo


# Explica se o clique começa, retoma ou consulta o resultado da sala.
func obter_dica() -> String:
	var acao := "Ver resultado" if concluida else ("Continuar questões" if iniciada else "Responder questões")
	return "Clique · " + acao + " · " + Config.SALAS[indice_sala]["nome"]


# Usa o destaque quente somente quando o painel está sob a mira.
func definir_foco(ativo: bool) -> void:
	tela.material_override = materiais["interativo" if ativo else "placa_fundo"]


# Solicita a interface sem acoplar este painel ao carregador JSON.
func interagir() -> void:
	solicitar_questoes.emit(indice_sala)


# Atualiza a indicação física após uma resposta ou conclusão.
func atualizar_progresso(respostas: int, total: int, acertos: int, terminou: bool) -> void:
	iniciada = respostas > 0
	concluida = terminou
	if concluida:
		status.text = "RESULTADO: %d / %d" % [acertos, total]
	elif iniciada:
		status.text = "CONTINUAR: %d / %d" % [respostas, total]
	else:
		status.text = "CLIQUE PARA COMEÇAR"
