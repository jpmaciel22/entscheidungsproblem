extends SceneTree
## Gera uma referência de estudo da biblioteca, separada da cena principal.

const Mundo = preload("res://scripts/mundo.gd")
const CENA := "res://referencias/biblioteca.tscn"
const GLB := "res://referencias/biblioteca_referencia.glb"


# Inicia a geração depois que a árvore de cena estiver disponível.
func _initialize() -> void:
	call_deferred("gerar")


# Usa as mesmas funções do jogo, sem iniciar jogador, menus ou questionário.
func gerar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://referencias"))
	var construtor := Mundo.new()
	construtor.criar_materiais()
	construtor.criar_biblioteca()
	var referencia := Node3D.new()
	referencia.name = "BibliotecaReferencia"
	for filho in construtor.get_children():
		construtor.remove_child(filho)
		referencia.add_child(filho)
		definir_owner(filho, referencia)
	construtor.free()
	root.add_child(referencia)
	var cena := PackedScene.new()
	var erro := cena.pack(referencia)
	if erro == OK:
		erro = ResourceSaver.save(cena, CENA)
	if erro != OK:
		push_error("Falha ao salvar a cena de referência.")
		quit(1)
		return
	# O GLB usa as malhas e os materiais; as placas Label3D não viram geometria.
	for placa in referencia.find_children("*", "Label3D", true, false):
		placa.free()
	var documento := GLTFDocument.new()
	var estado := GLTFState.new()
	erro = documento.append_from_scene(referencia, estado)
	if erro == OK:
		erro = documento.write_to_filesystem(estado, GLB)
	if erro != OK:
		push_error("Falha ao salvar o GLB de referência.")
		quit(1)
		return
	print("Referências geradas: ", CENA, " e ", GLB)
	quit()


# Faz o Godot salvar também as peças e colisões criadas pelo construtor.
func definir_owner(no: Node, dono: Node) -> void:
	no.owner = dono
	for filho in no.get_children():
		definir_owner(filho, dono)
