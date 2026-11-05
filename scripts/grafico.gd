extends Control
## Desenho matemático usado pela ferramenta que gera os PNGs das questões.

const Config = preload("res://scripts/configuracao.gd")
var dados: Dictionary = {}


# Converte coordenadas cartesianas em pixels dentro da área do gráfico.
func projetar(x: float, y: float) -> Vector2:
	var area := size - Config.GRAFICO_MARGEM * 2.0
	return Config.GRAFICO_MARGEM + Vector2(
		(x - Config.GRAFICO_X.x) / (Config.GRAFICO_X.y - Config.GRAFICO_X.x) * area.x,
		(Config.GRAFICO_Y.y - y) / (Config.GRAFICO_Y.y - Config.GRAFICO_Y.x) * area.y)


# Desenha grade, eixos numerados e curva exata, sem informar a resposta.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Config.CORES["placa_fundo"])
	var fonte := ThemeDB.fallback_font
	var cor: Color = Config.CORES["placa_texto"]
	for x in range(int(Config.GRAFICO_X.x), int(Config.GRAFICO_X.y) + 1):
		draw_line(projetar(x, Config.GRAFICO_Y.x), projetar(x, Config.GRAFICO_Y.y), Config.CORES["parede_interna"], 1.0)
		if x != 0:
			draw_string(fonte, projetar(x, 0) + Config.GRAFICO_NUMERO_X_OFFSET, str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, Config.GRAFICO_FONTE, cor)
	for y in range(int(Config.GRAFICO_Y.x), int(Config.GRAFICO_Y.y) + 1):
		draw_line(projetar(Config.GRAFICO_X.x, y), projetar(Config.GRAFICO_X.y, y), Config.CORES["parede_interna"], 1.0)
		if y != 0:
			draw_string(fonte, projetar(0, y) + Config.GRAFICO_NUMERO_Y_OFFSET, str(y), HORIZONTAL_ALIGNMENT_LEFT, -1, Config.GRAFICO_FONTE, cor)
	draw_line(projetar(Config.GRAFICO_X.x, 0), projetar(Config.GRAFICO_X.y, 0), cor, 2.0)
	draw_line(projetar(0, Config.GRAFICO_Y.x), projetar(0, Config.GRAFICO_Y.y), cor, 2.0)
	draw_string(fonte, projetar(Config.GRAFICO_X.y, 0) + Config.GRAFICO_EIXO_X_OFFSET, "x", HORIZONTAL_ALIGNMENT_LEFT, -1, Config.GRAFICO_FONTE, cor)
	draw_string(fonte, projetar(0, Config.GRAFICO_Y.y) + Config.GRAFICO_EIXO_Y_OFFSET, "y", HORIZONTAL_ALIGNMENT_LEFT, -1, Config.GRAFICO_FONTE, cor)
	draw_string(fonte, projetar(0, 0) + Config.GRAFICO_ZERO_OFFSET, "0", HORIZONTAL_ALIGNMENT_LEFT, -1, Config.GRAFICO_FONTE, cor)
	var anterior := Vector2.ZERO
	var anterior_valido := false
	var passos := int((Config.GRAFICO_X.y - Config.GRAFICO_X.x) / Config.GRAFICO_PASSO)
	for i in range(passos + 1):
		var x := Config.GRAFICO_X.x + i * Config.GRAFICO_PASSO
		var y: float = dados["a"] * x * x + dados["b"] * x + dados["c"]
		var valido := y >= Config.GRAFICO_Y.x and y <= Config.GRAFICO_Y.y
		var ponto := projetar(x, y)
		if valido and anterior_valido:
			draw_line(anterior, ponto, Config.CORES["tapete"], Config.GRAFICO_LINHA, true)
		anterior = ponto
		anterior_valido = valido
