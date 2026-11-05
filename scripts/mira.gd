extends Control
## Mira pequena desenhada por código, com contorno discreto para manter a leitura.

const Config = preload("res://scripts/configuracao.gd")
var interativo := false:
	set(valor):
		if interativo != valor:
			interativo = valor
			queue_redraw()


# Redesenha ao mudar o tamanho da janela e deixa os cliques atravessarem.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


# Desenha quatro traços com as cores da interface, sem texturas.
func _draw() -> void:
	var centro := size / 2.0
	var cor: Color = Config.CORES["interativo" if interativo else "hud"]
	for direcao in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var inicio: Vector2 = centro + direcao * Config.MIRA_ESPACO
		var fim: Vector2 = centro + direcao * (Config.MIRA_ESPACO + Config.MIRA_BRACO)
		draw_line(inicio, fim, Config.CORES["painel"], Config.MIRA_ESPESSURA + 2.0 * Config.MIRA_CONTORNO)
		draw_line(inicio, fim, cor, Config.MIRA_ESPESSURA)
