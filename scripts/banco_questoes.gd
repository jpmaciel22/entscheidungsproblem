extends RefCounted
## Carregador genérico: valida todo o banco antes de oferecer uma questão.

const Config = preload("res://scripts/configuracao.gd")


# Lê um arquivo JSON e devolve questões válidas ou uma mensagem legível.
static func carregar(caminho: String) -> Dictionary:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return falha("Não foi possível abrir " + caminho + ".")
	var parser := JSON.new()
	var erro := parser.parse(arquivo.get_as_text())
	if erro != OK:
		return falha("JSON inválido em %s, linha %d: %s" % [caminho, parser.get_error_line(), parser.get_error_message()])
	return validar(parser.data)


# Confere quantidade, tipos, quatro alternativas e índice inteiro entre 0 e 3.
static func validar(dados: Variant) -> Dictionary:
	if not dados is Array:
		return falha("O arquivo precisa conter uma lista de questões entre colchetes.")
	if dados.size() < Config.QUESTOES_POR_SALA:
		return falha("Cada sala precisa ter pelo menos %d questões." % Config.QUESTOES_POR_SALA)
	var questoes: Array = []
	for i in range(dados.size()):
		var entrada: Variant = dados[i]
		var prefixo := "Questão %d: " % (i + 1)
		if not entrada is Dictionary:
			return falha(prefixo + "o item precisa ser um objeto JSON.")
		for campo in ["enunciado", "explicacao"]:
			if not entrada.get(campo) is String or entrada[campo].strip_edges().is_empty():
				return falha(prefixo + "preencha o campo " + campo + ".")
		var alternativas: Variant = entrada.get("alternativas")
		if not alternativas is Array or alternativas.size() != 4:
			return falha(prefixo + "informe exatamente quatro alternativas.")
		for alternativa in alternativas:
			if not alternativa is String or alternativa.strip_edges().is_empty():
				return falha(prefixo + "todas as alternativas precisam ter texto.")
		var correto: Variant = entrada.get("indice_correto")
		if typeof(correto) != TYPE_INT and typeof(correto) != TYPE_FLOAT:
			return falha(prefixo + "indice_correto precisa ser um número inteiro de 0 a 3.")
		if not is_finite(float(correto)) or float(correto) != floorf(float(correto)) or correto < 0 or correto > 3:
			return falha(prefixo + "indice_correto precisa ser um número inteiro de 0 a 3.")
		var imagem: Variant = entrada.get("imagem", "")
		if not imagem is String:
			return falha(prefixo + "imagem precisa ser um caminho de arquivo ou texto vazio.")
		for campo in ["id", "fonte", "url_fonte"]:
			if not entrada.get(campo, "") is String:
				return falha(prefixo + campo + " precisa ser um texto.")
		questoes.append({
			"enunciado": entrada["enunciado"], "imagem": imagem,
			"alternativas": alternativas.duplicate(), "indice_correto": int(correto),
			"explicacao": entrada["explicacao"],
			"id": entrada.get("id", ""), "fonte": entrada.get("fonte", ""),
			"url_fonte": entrada.get("url_fonte", ""),
		})
	return {"questoes": questoes, "erro": ""}


# Padroniza o retorno de erro para que a interface consiga continuar funcionando.
static func falha(mensagem: String) -> Dictionary:
	return {"questoes": [], "erro": mensagem}
