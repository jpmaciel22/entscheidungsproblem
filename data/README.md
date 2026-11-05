# Questões das salas

Cada arquivo contém uma lista JSON com **pelo menos quinze questões**. Esta versão
tem quinze por sala, 45 no total. Bancos maiores são aceitos, e o total do
placar acompanha o tamanho real da lista.

Filosofia e probabilidade contêm adaptações de itens do ENEM para quatro
alternativas, com enunciados e explicações próprios. As quinze questões de gráficos
são autorais. A origem é exibida no jogo; as referências estão em `FONTES.md`.

Os arquivos são `filosofia.json`, `geometria_analitica.json` e `probabilidade.json`.
Você pode solicitar pelo chat a inclusão ou a alteração de qualquer questão.
Não é necessário mexer nos scripts nem no editor do Godot.

Exemplo do formato, caso queira preencher os dados depois:

```json
[
  {
    "enunciado": "Qual função corresponde ao gráfico?",
    "imagem": "res://assets/graficos/reta_crescente.png",
    "alternativas": ["f(x) = x − 1", "f(x) = −x + 1", "f(x) = 2x + 1", "f(x) = x + 1"],
    "indice_correto": 3,
    "explicacao": "A reta tem coeficiente angular 1 e intercepta o eixo y em 1."
  }
]
```

- `enunciado`: texto da pergunta, obrigatório.
- `imagem`: caminho de um PNG; pode ser omitido ou ficar como `""`.
- `alternativas`: exatamente quatro textos, na ordem A, B, C, D.
- `indice_correto`: número inteiro entre **0 e 3**. A = 0, B = 1, C = 2, D = 3.
- `explicacao`: explicação curta, exibida após qualquer resposta, obrigatória.
- `id`: identificador da questão; opcional para o carregador.
- `fonte`: descrição da origem, exibida no jogo; opcional.
- `url_fonte`: link da prova original para conferência; opcional.

Use UTF-8 para preservar acentos. Depois de alterar os dados, encerre o teste
com F8 e rode novamente com F5. Os arquivos são carregados ao iniciar a partida.

Os quinze gráficos incluem seis retas (uma horizontal) e nove parábolas, com eixos numerados.
Os PNGs estão em `assets/graficos/`, com eixos e escala numérica. A ferramenta
em `ferramentas/gerar_graficos.gd` já foi executada: não é preciso gerar nada.

Os bancos são validados por inteiro antes de começar. Se algum dado estiver
inválido ou tiver menos de quinze itens, a sala mostra a causa e não oferece questões parciais. Uma imagem
ausente usa um placeholder; as outras salas seguem acessíveis normalmente.
