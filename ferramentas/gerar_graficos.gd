extends SceneTree
## Ferramenta já executada nesta entrega. Não é necessário rodá-la manualmente.

const Config = preload("res://scripts/configuracao.gd")
const Grafico = preload("res://scripts/grafico.gd")


# Aguarda a árvore estar disponível antes de montar os gráficos.
func _initialize() -> void:
	call_deferred("gerar")


# Desenha uma única vez e salva cada função como PNG em assets/graficos/.
func gerar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/graficos"))
	for dados in Config.GRAFICOS_QUESTOES:
		var viewport := SubViewport.new()
		viewport.size = Config.GRAFICO_TAMANHO
		viewport.disable_3d = true
		root.add_child(viewport)
		var grafico := Grafico.new()
		grafico.dados = dados
		grafico.size = Vector2(Config.GRAFICO_TAMANHO)
		viewport.add_child(grafico)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var imagem := viewport.get_texture().get_image()
		var erro := imagem.save_png(dados["arquivo"])
		if erro != OK:
			push_error("Não foi possível salvar " + dados["arquivo"])
			quit(1)
			return
		print("Gráfico gerado: ", dados["arquivo"])
		viewport.queue_free()
	quit()
