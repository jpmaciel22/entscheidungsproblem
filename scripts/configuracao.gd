extends RefCounted
## Configuração central. Medidas em metros; fachada voltada para +Z.

const CORES := {
	"ceu": Color("A9BCCB"), "horizonte": Color("C9D3DA"),
	"grama": Color("7C868E"), "caminho": Color("9AA3AB"),
	"pedra": Color("D5DADE"), "parede": Color("B7BEC4"),
	"rodape": Color("7C868E"), "telhado": Color("3F5468"),
	"porta": Color("2F4254"), "janela": Color("3F5468"),
	"ouro": Color("D5DADE"), "piso": Color("9AA3AB"),
	"tronco": Color("36485A"), "folhas": Color("566B80"),
	"folhas_claras": Color("7E93A8"), "texto": Color("E8ECEF"),
	"parede_interna": Color("C4CBD1"), "tapete": Color("4E6A85"),
	"estante": Color("36485A"), "mesa": Color("566B80"),
	"livro_0": Color("5B7A99"), "livro_1": Color("7E93A8"),
	"livro_2": Color("3F5468"), "livro_3": Color("A3B1BD"),
	"livro_4": Color("6C7A89"),
	"placa_fundo": Color("E3E7EA"), "placa_texto": Color("22303C"),
	"hud": Color("E8ECEF"), "painel": Color("1F2B36"),
	"alternativa": Color("2F4254"), "alternativa_hover": Color("3F5468"),
	"alternativa_selecionada": Color("5B7A99"),
	"acerto": Color("5E8C7B"), "erro": Color("A8666B"),
	"interativo": Color("D9B77A"),
	"sol": Color("FFF4E0"), "ambiente": Color("8FA3B5"),
	"luz_interna": Color("F2EBDD"),
}
const JOGADOR_INICIO := Vector3(0, 0.08, 19)
const JOGADOR_VELOCIDADE := 4.5
const JOGADOR_ACELERACAO := 18.0
const JOGADOR_GRAVIDADE := 22.0
const JOGADOR_IMPULSO_PULO := 7.0
const JOGADOR_ALTURA := 1.8
const JOGADOR_RAIO := 0.3
const JOGADOR_OLHOS := 1.65
const JOGADOR_SENSIBILIDADE := 0.0025
const JOGADOR_LIMITE_OLHAR := 80.0
const JOGADOR_FOV := 90.0
const JOGADOR_DISTANCIA_VISAO := 120.0
const JOGADOR_RETORNO_Y := -8.0
const JOGADOR_AJUSTE_CHAO := 0.25
const ACOES := {
	"andar_frente": KEY_W, "andar_tras": KEY_S,
	"andar_esquerda": KEY_A, "andar_direita": KEY_D,
	"pular": KEY_SPACE,
}
const SOL_ROTACAO := Vector3(-48, -28, 0)
const SOL_COR := CORES["sol"]
const SOL_ENERGIA := 0.65
const SOL_SOMBRAS := false
const AMBIENTE_COR := CORES["ambiente"]
const AMBIENTE_ENERGIA := 0.45
const CEU_TOPO := CORES["ceu"]
const CEU_HORIZONTE := CORES["horizonte"]
const CAMADA_EXTERIOR := 1
const CAMADA_INTERIOR := 2
# O volume acompanha o prédio; a neve ocupa somente os quatro lados do terreno.
const BIBLIOTECA_INTERIOR := AABB(Vector3(-11, -1, -13), Vector3(22, 7.7, 14))
const NEVE_AREAS := [
	[Rect2(-31, 1.8, 62, 29.2), 1400],
	[Rect2(-31, -31, 62, 17.2), 450],
	[Rect2(-31, -13.8, 19.2, 15.6), 250],
	[Rect2(11.8, -13.8, 19.2, 15.6), 250],
]
const NEVE_ALTURA := 8.0
const NEVE_DURACAO := 6.0
const NEVE_FLOCO_RAIO := 0.035
# Duas faixas chapadas de céu, sem degradê nem disco solar.
const CEU_SHADER := """shader_type sky;
uniform vec4 cor_topo : source_color;
uniform vec4 cor_horizonte : source_color;
uniform float altura_horizonte;
void sky() { COLOR = EYEDIR.y > altura_horizonte ? cor_topo.rgb : cor_horizonte.rgb; }
"""
const CEU_ALTURA_HORIZONTE := 0.035

# Cada bloco contém nome, tamanho, posição central, cor e presença de colisão.
const TERRENO := [
	["Terreno", Vector3(64, 0.4, 64), Vector3(0, -0.2, 0), "grama", true],
	["Caminho", Vector3(5, 0.01, 19), Vector3(0, 0, 13.5), "caminho", false],
	["Patio", Vector3(26, 0.012, 6), Vector3(0, 0.001, 4.5), "caminho", false],
	["BordaFrente", Vector3(64, 0.65, 0.4), Vector3(0, 0.325, 31.5), "rodape", true],
	["BordaFundo", Vector3(64, 0.65, 0.4), Vector3(0, 0.325, -31.5), "rodape", true],
	["BordaEsquerda", Vector3(0.4, 0.65, 64), Vector3(-31.5, 0.325, 0), "rodape", true],
	["BordaDireita", Vector3(0.4, 0.65, 64), Vector3(31.5, 0.325, 0), "rodape", true],
]
const CASCA_BIBLIOTECA := [
	["Piso", Vector3(22, 0.2, 14), Vector3(0, -0.094, -6), "piso", false],
	["ParedeEsquerda", Vector3(0.4, 6.4, 14), Vector3(-11, 3.2, -6), "parede", true],
	["ParedeDireita", Vector3(0.4, 6.4, 14), Vector3(11, 3.2, -6), "parede", true],
	["ParedeFundo", Vector3(22, 6.4, 0.4), Vector3(0, 3.2, -13), "parede", true],
	["Cobertura", Vector3(23, 0.4, 15), Vector3(0, 6.5, -6), "telhado", true],
]
const FACHADA := [
	["FrenteEsquerda", Vector3(9, 6.4, 0.4), Vector3(-6.5, 3.2, 1), "parede", true],
	["FrenteDireita", Vector3(9, 6.4, 0.4), Vector3(6.5, 3.2, 1), "parede", true],
	["SobreEntrada", Vector3(4, 2.8, 0.4), Vector3(0, 5, 1), "parede", true],
	["RodapeE", Vector3(9, 0.4, 0.16), Vector3(-6.5, 0.2, 1.26), "rodape", false],
	["RodapeD", Vector3(9, 0.4, 0.16), Vector3(6.5, 0.2, 1.26), "rodape", false],
	["Cornija", Vector3(23.4, 0.26, 0.85), Vector3(0, 6.25, 1.25), "pedra", false],
	["Placa", Vector3(15.8, 0.82, 0.18), Vector3(0, 5.22, 1.36), "porta", false],
	["Friso", Vector3(16, 0.06, 0.22), Vector3(0, 4.75, 1.36), "ouro", false],
]
const FRONTON_TAMANHO := Vector3(23.4, 2.1, 0.9)
const FRONTON_POSICAO := Vector3(0, 7.42, 1.18)
const FRONTON_COR := "pedra"
const LOGO_ARQUIVO := "res://assets/unijorge.png"
const LOGO_POSICAO := Vector3(0, 7.25, 1.65)
const LOGO_LIMITE := Vector2(1.8, 1.8)
const COLUNAS_X := [-10.3, -3.0, 3.0, 10.3]
const COLUNA_PARTES := [
	[Vector3(0.7, 0.25, 0.65), Vector3(0, 0.125, 1.5)],
	[Vector3(0.4, 4.3, 0.4), Vector3(0, 2.4, 1.5)],
	[Vector3(0.7, 0.22, 0.65), Vector3(0, 4.65, 1.5)],
]
const PORTA_MOLDURA := [
	["BatenteE", Vector3(0.22, 3.7, 0.6), Vector3(-2, 1.85, 1.22), "pedra", true],
	["BatenteD", Vector3(0.22, 3.7, 0.6), Vector3(2, 1.85, 1.22), "pedra", true],
	["Verga", Vector3(4.22, 0.26, 0.6), Vector3(0, 3.68, 1.22), "pedra", true],
	["PlacaEntrada", Vector3(3.1, 0.48, 0.14), Vector3(0, 4.15, 1.35), "porta", false],
]
# Duas folhas já abertas. O vão central está livre nesta etapa.
const PORTA_FOLHAS := [Vector3(-2.02, 1.7, 0.1), Vector3(2.02, 1.7, 0.1)]
const PORTA_FOLHA_TAMANHO := Vector3(0.12, 3.4, 1.7)
const PORTA_DETALHE_TAMANHO := Vector3(0.025, 2.6, 1.15)
const PORTA_DETALHE_OFFSET := Vector3(0.07, 0, 0)
const PORTA_MACANETA_TAMANHO := Vector3(0.14, 0.34, 0.07)
const PORTA_MACANETA_OFFSET := Vector3(0, -0.1, -0.5)
const JANELAS_X := [-7.7, -5.1, 5.1, 7.7]
const JANELA_PARTES := [
	[Vector3(1.8, 2.65, 0.2), Vector3(0, 2.8, 1.27), "pedra"],
	[Vector3(1.5, 2.35, 0.08), Vector3(0, 2.8, 1.4), "janela"],
	[Vector3(0.06, 2.35, 0.06), Vector3(0, 2.8, 1.46), "ouro"],
	[Vector3(1.5, 0.06, 0.06), Vector3(0, 2.8, 1.46), "ouro"],
	[Vector3(2, 0.14, 0.5), Vector3(0, 1.44, 1.4), "pedra"],
]
const ARVORES := [Vector3(-15, 0, 3), Vector3(15, 0, 3)]
const VASO_TAMANHO := Vector3(2.1, 0.65, 2.1)
const VASO_OFFSET := Vector3(0, 0.325, 0)
const TRONCO_ALTURA := 2.7
const TRONCO_RAIO := 0.18
const TRONCO_OFFSET := Vector3(0, 1.8, 0)
const COPAS := [
	[1.8, 0.65, 2.1, Vector3(0, 3.5, 0), "folhas"],
	[1.25, 0.15, 1.7, Vector3(0, 4.85, 0), "folhas_claras"],
]
const CILINDRO_SEGMENTOS := 7
const BANCOS := [Vector3(-7, 0, 5.2), Vector3(7, 0, 5.2)]
const BANCOS_PISO_OFFSET := Vector3(0, 0.007, 0)
const BANCO_PARTES := [
	[Vector3(3.2, 0.18, 0.8), Vector3(0, 0.55, 0), "porta"],
	[Vector3(3.2, 0.65, 0.12), Vector3(0, 0.95, -0.38), "porta"],
	[Vector3(0.2, 0.5, 0.65), Vector3(-1.15, 0.25, 0), "pedra"],
	[Vector3(0.2, 0.5, 0.65), Vector3(1.15, 0.25, 0), "pedra"],
]
const PLACA_TITULO := "KONZEPT"
const PLACA_POSICAO := Vector3(0, 5.22, 1.47)
const PLACA_ESCALA := 0.010
const ENTRADA_TEXTO := "B I B L I O T E C A"
const ENTRADA_TEXTO_POSICAO := Vector3(0, 4.15, 1.45)
const ENTRADA_TEXTO_ESCALA := 0.0037
const FONTE_3D_TAMANHO := 64
const HUD_MARGEM := 24.0
const HUD_TAMANHO := Vector2(570, 112)
const HUD_TITULO_FONTE := 21
const HUD_TEXTO_FONTE := 16
const HUD_ESPACO := 8
const HUD_TITULO := "KONZEPT  /  BIBLIOTECA"
const HUD_CONTROLES := "WASD · Caminhar   |   Espaço · Pular   |   Mouse · Olhar\nClique · Interagir   |   Esc · Liberar mouse   |   Tab · Menu"
const HUD_OPACIDADE := 0.90

# Interior: recepção à frente e três salas lado a lado ao fundo.
const INTERIOR_BLOCOS := [
	["Forro", Vector3(21.6, 0.08, 13.6), Vector3(0, 6.25, -6), "parede_interna", false],
	["RevestimentoE", Vector3(0.04, 6.1, 13.6), Vector3(-10.78, 3.05, -6), "parede_interna", false],
	["RevestimentoD", Vector3(0.04, 6.1, 13.6), Vector3(10.78, 3.05, -6), "parede_interna", false],
	["RevestimentoFundo", Vector3(21.6, 6.1, 0.04), Vector3(0, 3.05, -12.78), "parede_interna", false],
	["RevestimentoFrenteE", Vector3(8.8, 6.1, 0.04), Vector3(-6.4, 3.05, 0.78), "parede_interna", false],
	["RevestimentoFrenteD", Vector3(8.8, 6.1, 0.04), Vector3(6.4, 3.05, 0.78), "parede_interna", false],
	["DivisoriaE", Vector3(0.18, 6.1, 6.8), Vector3(-3.65, 3.05, -9.4), "parede_interna", true],
	["DivisoriaD", Vector3(0.18, 6.1, 6.8), Vector3(3.65, 3.05, -9.4), "parede_interna", true],
	["TapeteRecepcao", Vector3(4.0, 0.014, 6.3), Vector3(0, 0.014, -2.5), "tapete", false],
]
const SALAS := [
	{"nome": "FILOSOFIA", "x": -7.25, "quadro": "res://assets/hegel.jpg"},
	{"nome": "GEOMETRIA ANALÍTICA", "x": 0.0, "quadro": "res://assets/godel.jpg"},
	{"nome": "PROBABILIDADE", "x": 7.25, "quadro": "res://assets/dice.jpg"},
]
const SALA_FRENTE_Z := -6.0
const SALA_PAREDE_PARTES := [
	[Vector3(2.65, 6.1, 0.18), Vector3(-2.225, 3.05, 0)],
	[Vector3(2.65, 6.1, 0.18), Vector3(2.225, 3.05, 0)],
	[Vector3(1.8, 3.3, 0.18), Vector3(0, 4.45, 0)],
]
const SALA_PLACA_TAMANHO := Vector3(5.4, 0.88, 0.1)
const SALA_PLACA_OFFSET := Vector3(0, 3.55, 0.16)
const SALA_NOME_OFFSET := Vector3(0, 3.55, 0.22)
const SALA_NOME_ESCALA := 0.0042
const SALA_TAPETE_TAMANHO := Vector3(4.4, 0.014, 4.9)
const SALA_TAPETE_OFFSET := Vector3(0, 0.014, -3.3)
# O banco olha para a esquerda; o quadro fica na parede à direita, atrás dele.
const SALA_BANCO_OFFSET := Vector3(1.5, 0.021, -3.4)
const SALA_BANCO_ANGULO := -PI / 2.0
const SALA_QUADRO_OFFSET := Vector3(3.35, 2.35, -3.4)
const SALA_QUADRO_ANGULO := -PI / 2.0
const SALA_QUADRO_LIMITE := Vector2(1.9, 2.1)
const SALA_QUADRO_BORDA := 0.07
const SALA_QUADRO_ESPESSURA := 0.08
const SALA_QUADRO_IMAGEM_Z := 0.041
const SALA_QUADRO_COR := "estante"
const PORTA_SALA_TAMANHO := Vector3(1.72, 2.75, 0.12)
const PORTA_SALA_OFFSET := Vector3(0, 1.375, 0)
# A origem física fica na dobradiça esquerda; a folha gira para dentro da sala.
const PORTA_SALA_DOBRADICA_OFFSET := Vector3(-PORTA_SALA_TAMANHO.x / 2.0, 0, 0)
const PORTA_SALA_FOLHA_OFFSET := -PORTA_SALA_DOBRADICA_OFFSET
const PORTA_SALA_ANGULO_ABERTURA := PI / 2.0
const PORTA_SALA_TEMPO := 0.65
const PORTA_SALA_MOLDURAS := [
	[Vector3(0.12, 2.9, 0.28), Vector3(-0.96, 1.45, 0)],
	[Vector3(0.12, 2.9, 0.28), Vector3(0.96, 1.45, 0)],
	[Vector3(2.04, 0.12, 0.28), Vector3(0, 2.85, 0)],
]
const PORTA_PUXADOR_TAMANHO := Vector3(0.07, 0.28, 0.12)
const PORTA_PUXADOR_OFFSET := Vector3(0.62, 0, 0.12)
const ESTANTES_RECEPCAO := [
	[Vector3(-9.8, 0, -2.5), PI / 2.0],
	[Vector3(9.8, 0, -2.5), -PI / 2.0],
]
const ESTANTE_PARTES := [
	[Vector3(2.8, 2.7, 0.10), Vector3(0, 1.35, -0.22)],
	[Vector3(0.12, 2.7, 0.55), Vector3(-1.4, 1.35, 0)],
	[Vector3(0.12, 2.7, 0.55), Vector3(1.4, 1.35, 0)],
]
const ESTANTE_PRATELEIRAS_Y := [0.18, 0.94, 1.7, 2.6]
const ESTANTE_PRATELEIRA_TAMANHO := Vector3(2.8, 0.1, 0.55)
const ESTANTE_COLISAO_TAMANHO := Vector3(2.92, 2.7, 0.55)
const ESTANTE_COLISAO_OFFSET := Vector3(0, 1.35, 0)
const LIVROS_POR_PRATELEIRA := 10
const LIVROS_BASE_Y := [0.23, 0.99, 1.75]
const LIVRO_LARGURA := 0.19
const LIVRO_ALTURAS := [0.47, 0.58, 0.52, 0.62, 0.49]
const LIVRO_PROFUNDIDADE := 0.32
const LIVRO_INICIO_X := -1.19
const LIVRO_PASSO_X := 0.255
const LIVRO_POSICAO_Z := 0.04
const MESAS_RECEPCAO := [Vector3(-5.6, 0, -2.3), Vector3(5.6, 0, -2.3)]
const MOVEIS_PISO_OFFSET := Vector3(0, 0.006, 0)
# Cada cadeira contém deslocamento em relação à mesa e rotação para olhar para ela.
const CADEIRAS_RECEPCAO := [
	[Vector3(0, 0, 1.12), PI],
	[Vector3(0, 0, -1.12), 0.0],
]
const MESA_PARTES := [
	[Vector3(2.6, 0.14, 1.3), Vector3(0, 0.92, 0)],
	[Vector3(0.14, 0.86, 0.95), Vector3(-1.05, 0.43, 0)],
	[Vector3(0.14, 0.86, 0.95), Vector3(1.05, 0.43, 0)],
]
const BANQUETAS_OFFSET := [Vector3(0, 0, 1.05), Vector3(0, 0, -1.05)]
const BANQUETA_ASSENTO := Vector3(0.65, 0.12, 0.65)
const BANQUETA_ASSENTO_OFFSET := Vector3(0, 0.5, 0)
const BANQUETA_BASE := Vector3(0.35, 0.44, 0.35)
const BANQUETA_BASE_OFFSET := Vector3(0, 0.22, 0)
const LUZES_INTERIORES := [Vector3(-5.5, 4.6, -5), Vector3(5.5, 4.6, -5)]
const LUZ_INTERIOR_ENERGIA := 0.7
const LUZ_INTERIOR_ALCANCE := 13.0
const LUZ_INTERIOR_ATENUACAO := 0.8
const LUMINARIA_TAMANHO := Vector3(2.0, 0.12, 0.65)
const LUMINARIA_DETALHE := Vector3(1.8, 0.04, 0.5)
const LUMINARIA_DETALHE_OFFSET := Vector3(0, -0.08, 0)

# Mãos, mira e interação: todos os estados usam os PNGs originais do usuário.
const MAOS_ARQUIVOS := {
	"idle": "res://assets/hand_idle.png",
	"point": "res://assets/hand_point.png",
	"click": "res://assets/hand_click.png",
}
const MAO_TAMANHO := Vector2(580, 580)
const MAO_OFFSET := Vector2(30, 35)
const MAO_BALANCO_AMPLITUDE := Vector2(2.0, 6.0)
const MAO_BALANCO_FREQUENCIA := 8.5
const MAO_BALANCO_SUAVIDADE := 10.0
const MAO_CLIQUE_DURACAO := 0.15
const MAO_CLIQUE_DESLOCAMENTO := 5.0
const MAO_PLACEHOLDER_TAMANHO := Vector2i(160, 160)
const MAO_PLACEHOLDER_BRACO := Rect2i(88, 92, 48, 68)
const MAO_PLACEHOLDER_PALMA := Rect2i(72, 70, 60, 48)
const MAO_PLACEHOLDER_DEDO := Rect2i(74, 30, 16, 55)
const MIRA_ESPESSURA := 2.0
const MIRA_BRACO := 5.0
const MIRA_ESPACO := 3.0
const MIRA_CONTORNO := 1.0
const INTERACAO_DISTANCIA := 3.2
const INTERACAO_DICA_OFFSET := Vector2(-260, 30)
const INTERACAO_DICA_TAMANHO := Vector2(520, 32)
const INTERACAO_DICA_FONTE := 18

# Etapa 4: bancos, painéis físicos, interface e gráficos das questões.
# Quantidade mínima; o carregador aceita mais e o placar acompanha o total real.
const QUESTOES_POR_SALA := 15
const QUESTOES_ARQUIVOS := [
	"res://data/filosofia.json",
	"res://data/geometria_analitica.json",
	"res://data/probabilidade.json",
]
const TERMINAL_OFFSET := Vector3(-2.5, 1.65, -3.4)
const TERMINAL_ANGULO := PI / 2.0
const TERMINAL_TAMANHO := Vector3(1.65, 1.15, 0.18)
const TERMINAL_TELA_TAMANHO := Vector3(1.45, 0.95, 0.035)
const TERMINAL_TELA_OFFSET := Vector3(0, 0, 0.105)
const TERMINAL_TEXTO_OFFSET := Vector3(0, 0.12, 0.13)
const TERMINAL_STATUS_OFFSET := Vector3(0, -0.2, 0.13)
const TERMINAL_TEXTO_ESCALA := 0.0028
const TERMINAL_STATUS_ESCALA := 0.0017
const TERMINAL_SUPORTE_TAMANHO := Vector3(0.15, 1.1, 0.16)
const TERMINAL_SUPORTE_OFFSET := Vector3(0, -1.1, 0)
const TERMINAL_BASE_TAMANHO := Vector3(0.75, 0.08, 0.6)
const TERMINAL_BASE_OFFSET := Vector3(0, -1.61, 0)
const QUIZ_CAMADA := 20
const QUIZ_MARGEM := 28.0
const QUIZ_LARGURA_MAX := 1080.0
const QUIZ_PAINEL_MARGEM := 24
const QUIZ_ESPACO := 12
const QUIZ_TITULO_FONTE := 24
const QUIZ_TEXTO_FONTE := 20
const QUIZ_DETALHE_FONTE := 16
const QUIZ_BOTAO_ALTURA := 52.0
const QUIZ_BOTAO_MARGEM := 16
const QUIZ_BORDA := 2
const QUIZ_RAIO := 6
const QUIZ_PAINEL_OPACIDADE := 0.97
const QUIZ_VEU_OPACIDADE := 0.72
const QUIZ_IMAGEM_ALTURA := 230.0
const QUIZ_BARRA_ALTURA := 6.0
const QUIZ_FOCO_BORDA := 2
const QUIZ_VOLTAR_LARGURA := 220.0
const QUIZ_LIMIAR_COLUNAS := 880.0
const QUIZ_IMAGEM_PROPORCAO := 0.9
const QUIZ_RESPOSTAS_PROPORCAO := 1.1
const PLACAR_MARGEM := 24.0
const PLACAR_LARGURA := 310.0
const PLACAR_ALTURA := 136.0
const PLACAR_TITULO := "PROGRESSO DAS SALAS"
const GRAFICO_TAMANHO := Vector2i(880, 440)
const GRAFICO_MARGEM := Vector2(58, 32)
const GRAFICO_X := Vector2(-4, 4)
const GRAFICO_Y := Vector2(-3, 5)
const GRAFICO_PASSO := 0.025
const GRAFICO_FONTE := 18
const GRAFICO_LINHA := 3.0
const GRAFICO_NUMERO_X_OFFSET := Vector2(-5, 22)
const GRAFICO_NUMERO_Y_OFFSET := Vector2(-28, 6)
const GRAFICO_EIXO_X_OFFSET := Vector2(12, 6)
const GRAFICO_EIXO_Y_OFFSET := Vector2(10, -10)
const GRAFICO_ZERO_OFFSET := Vector2(-16, 22)
const GRAFICOS_QUESTOES := [
	{"arquivo": "res://assets/graficos/reta_crescente.png", "a": 0.0, "b": 1.0, "c": 1.0},
	{"arquivo": "res://assets/graficos/parabola.png", "a": 1.0, "b": 0.0, "c": -1.0},
	{"arquivo": "res://assets/graficos/reta_decrescente.png", "a": 0.0, "b": -2.0, "c": 2.0},
	{"arquivo": "res://assets/graficos/reta_2x_menos_3.png", "a": 0.0, "b": 2.0, "c": -3.0},
	{"arquivo": "res://assets/graficos/reta_meio_decrescente.png", "a": 0.0, "b": -0.5, "c": 2.0},
	{"arquivo": "res://assets/graficos/parabola_maximo_4.png", "a": -1.0, "b": 0.0, "c": 4.0},
	{"arquivo": "res://assets/graficos/parabola_direita.png", "a": 1.0, "b": -2.0, "c": -1.0},
	{"arquivo": "res://assets/graficos/parabola_aberta.png", "a": 0.5, "b": 0.0, "c": -2.0},
	{"arquivo": "res://assets/graficos/parabola_esquerda.png", "a": 1.0, "b": 2.0, "c": -1.0},
	{"arquivo": "res://assets/graficos/parabola_maximo_deslocado.png", "a": -0.5, "b": -1.0, "c": 2.5},
	{"arquivo": "res://assets/graficos/reta_tres_quartos.png", "a": 0.0, "b": 0.75, "c": 0.5},
	{"arquivo": "res://assets/graficos/reta_constante_3.png", "a": 0.0, "b": 0.0, "c": 3.0},
	{"arquivo": "res://assets/graficos/parabola_quarto.png", "a": 0.25, "b": 0.0, "c": -1.0},
	{"arquivo": "res://assets/graficos/parabola_raizes_1_3.png", "a": 1.0, "b": -4.0, "c": 3.0},
	{"arquivo": "res://assets/graficos/parabola_maximo_direita.png", "a": -0.25, "b": 0.5, "c": 2.75},
]

# Cena opcional para posicionar modelos de árvore pelo editor.
const ARVORE_PERSONALIZADA_COLISAO_RAIO := 0.25
const ARVORE_PERSONALIZADA_COLISAO_ALTURA := 2.6
const PREVIA_NOME := "ReferenciaDoMundo"

# Etapa 5: menus, câmera de apresentação e acabamento leve.
const MENU_CAMADA := 30
const MENU_CAMERA_POSICAO := Vector3(22, 8, 23)
const MENU_CAMERA_ALVO := Vector3(0, 3.1, -2)
const MENU_CAMERA_FOV := 57.0
const MENU_MARGEM := 40.0
const MENU_LARGURA := 540.0
const MENU_RESULTADO_LARGURA := 800.0
const MENU_ALTURA_MAX := 640.0
const MENU_ALTURA := 360.0
const MENU_PAINEL_MARGEM := 28
const MENU_ESPACO := 12
const MENU_TITULO_FONTE := 28
const MENU_PLACAR_FONTE := 52
const MENU_FUNDO_OPACIDADE := 0.22
const MENU_PAINEL_OPACIDADE := 0.96
const MENU_MARCA := "BIBLIOTECA DO CONHECIMENTO"
const MENU_TITULO := "Konzept"
const MENU_PAUSA_TEXTO := "PAUSADO"
const MENU_CONTROLES := "WASD para caminhar · Espaço para pular · Mouse para olhar\nMire e clique nas portas e nos painéis QUESTÕES.\nEsc libera o mouse · Tab abre este menu."
const MENU_FINAL_TITULO := "Percurso concluído"
const MENU_FINAL_MENSAGEM := "Você completou as três salas da biblioteca."
const GUIA_ENTRADA := [
	["GuiaEntradaE", Vector3(0.05, 0.012, 5.9), Vector3(-1.9, 0.018, -2.5), "pedra", false],
	["GuiaEntradaD", Vector3(0.05, 0.012, 5.9), Vector3(1.9, 0.018, -2.5), "pedra", false],
]
const MENU_ATALHO := KEY_TAB
