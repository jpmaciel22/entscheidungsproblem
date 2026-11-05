"""Atualiza a documentação dos bancos e das referências. Já executado na entrega."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANCOS = {
    nome: json.loads((ROOT / "data" / (nome + ".json")).read_text(encoding="utf-8"))
    for nome in ["filosofia", "probabilidade", "geometria_analitica"]
}
TOTAL = sum(len(itens) for itens in BANCOS.values())

sources = [f"""# Origem das questões e critérios de adaptação

São {len(BANCOS['filosofia'])} questões por sala, {TOTAL} no total, em nível de ensino médio.
Filosofia e probabilidade contêm adaptações didáticas ou temáticas de itens
dos cadernos oficiais do INEP. Os enunciados foram reescritos e as explicações
são próprias. As cinco alternativas originais deram lugar a quatro: as letras
do jogo não correspondem necessariamente às do gabarito original.

A independência de eventos e a uniformidade dos sorteios foram explicitadas
quando necessárias ao cálculo. O item sobre Tomás de Aquino adapta o tema
original para a relação entre razão e fé. Não são reproduções integrais da prova.

As {len(BANCOS['geometria_analitica'])} questões de gráficos são autorais, sobre funções afins, constantes e quadráticas,
com leitura do plano cartesiano, inclinação, interceptos, raízes e vértices.
Não são apresentadas como questões oficiais do ENEM.

Portal: [Provas e gabaritos do INEP](https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/enem/provas-e-gabaritos).

"""]
for filename, title in [
    ("filosofia", "Filosofia"), ("probabilidade", "Probabilidade"),
    ("geometria_analitica", "Geometria / gráficos"),
]:
    items = BANCOS[filename]
    sources.append(f"## {title}\n\n| ID | Referência | Resposta no jogo |\n| --- | --- | --- |\n")
    for item in items:
        source = item["fonte"]
        if item.get("url_fonte"):
            source = f"[{source}]({item['url_fonte']})"
        sources.append(f"| {item['id']} | {source} | {chr(65 + item['indice_correto'])} |\n")
    sources.append("\n")
sources.append(f"""## Gabaritos oficiais também consultados

- [2015, regular, 2º dia, Cinza](https://download.inep.gov.br/educacao_basica/enem/gabaritos/2015/CADERNO_6_CINZA_DOMINGO.pdf): 139/C no original.
- [2015, 2ª aplicação, 2º dia, Cinza](https://download.inep.gov.br/educacao_basica/enem/gabaritos/2015/GAB_ENEM_2015_2aAPLICACAO_DIA_02_06_CINZA.pdf): 171/C no original.
- [2017, regular, 1º dia, Azul](https://download.inep.gov.br/educacao_basica/enem/gabaritos/2017/cad_1_gabarito_azul_5112017.pdf): 84/B e 85/C no original.
- [2017, PPL, 2º dia, Amarelo](https://download.inep.gov.br/educacao_basica/enem/ppl/2017/gabaritos/GAB_ENEM_2017_2_APL_DIA_2_Amarelo_cad_5.pdf): 140/D no original.

As explicações justificam as respostas das adaptações. Os cálculos das {len(BANCOS['probabilidade'])}
questões de probabilidade e as equações dos {len(BANCOS['geometria_analitica'])} gráficos também foram
conferidos separadamente na validação.

Na ampliação para 15 itens foram consultados os mesmos cadernos já citados.
As adaptações temáticas acrescentam perguntas próprias sobre os contextos
originais: pares de vogais (PPL 2014/172), sorteio de cartas equivalentes
(2015 Azul/139) e razão de probabilidades em cartelas (2013 Amarelo/176).
O item de parafusos (2013 Amarelo/175) pede a probabilidade numérica em vez
da classificação usada na prova. Todas essas alterações estão identificadas.
""")
(ROOT / "data" / "FONTES.md").write_text("".join(sources), encoding="utf-8")

manifest = json.loads((ROOT / "referencias" / "manifesto.json").read_text(encoding="utf-8"))
guide = ["""# Referências 3D para Godot e Blender

São **25 arquivos GLB** em `objetos/`, com as formas, cores e medidas do jogo.
As placas estão **sem texto**, como solicitado. No jogo, o texto continua sendo
um Label3D separado e criado pelo código.

## Abrir no Blender

1. Use **Arquivo → Importar → glTF 2.0 (.glb/.gltf)**.
2. Escolha `objetos/mundo_completo.glb` para ver tudo, ou uma peça individual.
3. Para remodelar o prédio, use `objetos/biblioteca_completa.glb` como referência.

As peças continuam separadas dentro dos arquivos. O mundo completo inclui
terreno, pátio, prédio, interior, árvores, bancos, mesas, estantes, livros,
portas, luminárias e placas. Os livros agrupados no jogo viraram malhas
individuais nestas referências. São cópias visuais estáticas: mãos 2D, menus,
céu, scripts e interação continuam no projeto Godot.

## Observar e medir no Godot

Abra **`referencias/biblioteca.tscn`**, na aba 3D. Selecione uma peça na árvore
de nós e abra **Mesh → Size** no Inspector. **Transform → Position** mostra
sua posição. Essa cena é uma cópia para estudo; editá-la não altera o jogo.

As medidas adotam uma unidade por metro. Godot usa Y para altura; Blender usa Z
e converte os eixos ao importar. A estrutura principal tem 22 m nominais de
largura, 14 m de profundidade e paredes de 6,4 m. O topo do frontão fica a
8,47 m acima do chão. Beirais e detalhes aumentam a largura/profundidade totais;
a caixa envolvente da biblioteca também inclui a espessura do piso.

Peças pequenas têm origem na base e centro em X/Z. Prédio, interior e terreno
conservam a origem do mundo, para encaixar entre si.

## Dimensões das referências

Valores em metros, na ordem **X × Y × Z do Godot**, calculados a partir das malhas.
No Blender, a dimensão vertical é Z.

| Arquivo | Dimensões X × Y × Z (m) | Malhas |
| --- | --- | --- |
"""]
for item in manifest:
    size = " × ".join(f"{value:.3f}".rstrip("0").rstrip(".") for value in item["dimensoes_xyz_m"])
    guide.append(f"| [{item['arquivo']}](objetos/{item['arquivo']}) | {size} | {item['malhas']} |\n")
guide.append("""
## Texto sobre uma placa feita no Blender

O GLB pode conter só a superfície e o suporte. No Godot, o código adiciona um
Label3D como filho e o coloca um pouco à frente da placa, evitando sobreposição.
O nome vem dos dados da sala: mudar o texto não exige editar o modelo no Blender.

## Geração

`ferramentas/gerar_referencias.gd` já foi executado. A ferramenta usa as funções
e medidas do jogo e grava cópias sem textos ou componentes de jogo. Ela precisa
do renderer gráfico Compatibility, sem `--headless`, para ler as instâncias
MultiMesh dos livros. Não é preciso executá-la manualmente nesta entrega.
A pasta `referencias/` é excluída da exportação do jogo para não aumentar o EXE.
""")
(ROOT / "referencias" / "README.md").write_text("".join(guide), encoding="utf-8")
print("Documentação atualizada em UTF-8.")
