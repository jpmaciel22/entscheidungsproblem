# Konzept — MVP completo

Jogo 3D em primeira pessoa para Godot 4.x, com renderer Compatibility.

A [análise técnica completa em PDF](documentacao/Konzept_Analise_Tecnica.pdf)
explica a construção do jogo, a arquitetura e o funcionamento dos scripts.
Há também uma [versão em Markdown](documentacao/Konzept_Analise_Tecnica.md).

## Como rodar

1. Abra `project.godot` no Godot, ou volte à janela do projeto já aberto.
2. Aperte **F5**. A cena principal já é `res://scenes/principal.tscn`.
3. Clique em **Jogar** no menu inicial.

Também é possível abrir diretamente `build/windows/Konzept.exe`,
sem instalar o Godot. O ZIP para compartilhar fica em
`build/Konzept_Windows.zip`: extraia antes de executar.

Você começa olhando para a biblioteca feita no Blender, com letreiro, logo da
Unijorge, pátio e entrada aberta.
Há neve caindo no exterior; o efeito para ao entrar no prédio e volta ao sair.
Há trilha de fundo em volume discreto, passos ao caminhar, som nas portas e
efeitos diferentes para acerto e erro. A música diminui durante as questões.
Entre para encontrar estantes com livros, mesas, bancos e tapete. Ao fundo,
há três salas identificadas: Filosofia, Geometria Analítica e Probabilidade.
As placas das portas mostram apenas o nome da matéria, sem números ou subtítulos.
As portas das salas abrem para dentro, girando pela dobradiça esquerda.
Em cada sala, o painel **QUESTÕES** fica mais ao fundo, à esquerda; há apenas
um banco voltado para ele e um quadro na parede direita, atrás do banco.
Os quadros usam `assets/hegel.jpg` (Filosofia), `assets/godel.jpg` (Geometria)
e `assets/dice.jpg` (Probabilidade), preservando a proporção das imagens.
Aproxime-se do painel e clique nele pela mira para começar.

| Controle | Ação |
| --- | --- |
| W / A / S / D | Caminhar |
| Espaço | Pular (com o personagem no chão) |
| Mouse | Olhar |
| Esc | Liberar o mouse e parar de caminhar |
| Tab durante a exploração | Abrir ou fechar o menu de pausa |
| Clique esquerdo com o mouse livre | Capturar o mouse novamente |
| Mira sobre uma porta próxima + clique | Abrir a sala |
| Mira sobre o painel QUESTÕES + clique | Iniciar, retomar ou consultar resultado |
| Clique em uma alternativa | Responder à questão |
| Esc durante as questões | Fechar a interface e preservar o progresso |
| F8 no editor | Encerrar o teste |

## Arquivos

- `scenes/principal.tscn`: somente um Node3D com script anexado.
- `scripts/configuracao.gd`: cores, medidas, posições, iluminação e movimento.
- `scripts/mundo.gd`: modelo da biblioteca, colisões, terreno e instruções.
- `scripts/jogador.gd`: cápsula física, câmera, controles e gravidade.
- `scripts/interior.gd`: recepção, três salas, móveis, livros e luzes internas.
- `scripts/porta.gd`: modelo das portas, colisão e abertura animada.
- `assets/biblioteca.glb` e `assets/porta.glb`: modelos originais do autor.
- `scripts/maos.gd`: sprites sobrepostos com estados e balanço ao caminhar.
- `scripts/mira.gd`: mira pequena desenhada por código.
- `scripts/terminal_sala.gd`: painel interativo dentro de cada sala.
- `scripts/banco_questoes.gd`: carregador e validação genérica dos arquivos JSON.
- `scripts/questionario.gd`: interface, respostas, feedback, retomada e placar.
- `scripts/fluxo_jogo.gd`: menu inicial, pausa, tela final e nova partida.
- `scripts/audio_jogo.gd`: trilha em loop, passos, abertura das portas e feedback sonoro.
- `assets/sons/`: os cinco WAVs fornecidos pelo autor, com os originais preservados.
- `export_presets.cfg`: exportação Windows 64 bits, com dados embutidos no EXE.
- `EXPORTAR_WINDOWS.md`: instruções curtas para gerar uma nova versão.
- `data/filosofia.json`, `geometria_analitica.json`, `probabilidade.json`: questões.
- `assets/graficos/`: quinze gráficos PNG reais para as questões de geometria.
- `scenes/paisagismo.tscn`: cena opcional para posicionar suas árvores no editor.
- `ARVORES_BLENDER.md`: passos e explicação da montagem de um mundo com cenas.
- `data/FONTES.md`: referências dos itens adaptados e dos exercícios autorais.
- `referencias/`: cena da biblioteca para inspeção e 25 objetos GLB de referência.
- `referencias/README.md`: como importar no Blender, consultar medidas e usar placas sem texto.
- `ferramentas/gerar_graficos.gd` e `scripts/grafico.gd`: geração dos gráficos,
  já executada nesta entrega; não requer ação manual.
- `assets/hand_idle.png`, `hand_point.png`, `hand_click.png`: sprites originais.

Não é necessário editar código, criar nós ou posicionar objetos no editor.
Peça os ajustes no chat: os parâmetros estão centralizados na configuração.

## Escopo

As cinco etapas estão implementadas: cenário, interior, mãos, interação,
questões em JSON, feedback, placar, menus, tela final e exportação para Windows.
Cada sala tem **quinze questões de ensino médio**, somando **45 questões**.
Filosofia e probabilidade usam adaptações de itens pesquisados nos cadernos
oficiais do ENEM. A origem aparece na interface e nos JSONs. As quinze questões de
gráficos são autorais, identificadas como tal, sobre funções afins e quadráticas.
O formato mantém quatro alternativas e explicação própria por questão.
O carregador exige pelo menos quinze questões por sala e aceita bancos maiores;
o resultado acompanha a quantidade real, sem precisar alterar os scripts.

Ao concluir as três salas, a tela final mostra cada pontuação e a soma da partida.
Nesta versão, o resultado de cada sala é **x/15**, e o total da partida é **x/45**.
Você pode continuar explorando, iniciar uma nova partida ou sair.

## O que testar

1. No menu inicial, clique em **Jogar**, caminhe até o prédio e entre.
2. Aproxime-se de uma das portas, aponte a mira e clique para abrir.
3. Entre e mire no painel **QUESTÕES**, logo após a porta; clique para começar.
4. Escolha uma alternativa: as opções serão bloqueadas, e aparecerá a explicação.
5. Clique em **Próxima questão**; na última, use **Ver resultado da sala**.
6. Clique em **Voltar à biblioteca** e visite os outros assuntos.
7. Confira o placar das três salas no canto inferior esquerdo durante a exploração.
8. Teste fechar uma questão com Esc e abrir o painel novamente: sua resposta,
   explicação e pontuação são preservadas durante a mesma partida.
9. Use **Tab** durante a exploração para pausar; **Continuar partida** preserva
   respostas, portas abertas e posição. A dica inicial desaparece sozinha.
10. Conclua as três salas para ver a tela final. **Explorar biblioteca** preserva
    o resultado; **Jogar novamente** zera a partida e retorna ao menu inicial.

Nas questões, o cursor fica livre, o jogador para e as mãos e a mira ficam
ocultas para facilitar a leitura. O botão de voltar retoma o controle do mouse.
Esc fecha as questões e mantém o cursor livre; clique no jogo para capturá-lo.
Em janela menor, o conteúdo pode ser rolado com a roda do mouse.

O progresso fica **somente na partida atual**. F8, fechar o jogo ou rodar F5 de
novo inicia uma partida do zero. Salas concluídas continuam acessíveis para
consultar o resultado; não há reinício automático que apague a pontuação.
O menu de pausa mostra somente o título do jogo, **PAUSADO**, os botões
**Continuar partida** e **Sair**, com as instruções de controle abaixo.

O balanço acompanha o movimento real, parando quando o jogador fica imóvel
ou esbarra em uma parede. Os três PNGs mantêm o mesmo enquadramento ao trocar.
Se algum sprite estiver ausente, um placeholder transparente é criado por código.

## Dados das questões

O formato está documentado em `data/README.md`. A imagem é opcional. Se houver
um caminho para PNG ausente, a interface mostra um placeholder. Um JSON inválido
mostra uma mensagem na própria sala, sem impedir a exploração das outras.
Você pode pedir alterações e novas questões pelo chat; não precisa editar scripts.

## Áudio

Os arquivos `soundtrack.wav`, `passos.wav`, `porta.wav`, `acertou.wav` e
`errou.wav`, em `assets/sons/`, são carregados uma vez pelo controlador de áudio.
A trilha acompanha menu, exploração e resultado, com volume reduzido durante
a leitura das questões. Os passos usam o movimento real do corpo e param no
ar, ao esbarrar sem se mover, ao abrir interfaces ou ao liberar o mouse.
O som da porta é espacial e parte da posição da porta aberta.

Acerto e erro tocam apenas ao registrar uma resposta nova; cliques repetidos
e a retomada de uma questão já respondida não repetem o efeito. Trocar de
janela suspende os sons; ao voltar, a música continua do mesmo ponto.
Os recortes de silêncio e os volumes ficam nas constantes `AUDIO_*` de
`scripts/configuracao.gd`. Os WAVs originais não são reescritos. As importações
dos quatro efeitos curtos usam PCM sem compressão para permitir o recorte
em memória; a trilha mantém a compressão de importação do motor.

O cenário combina modelos do autor com primitivas e materiais compartilhados,
uma luz direcional externa e três luzes suaves internas, todas sem sombras.
O céu tem duas faixas de cor chapada, sem degradê ou disco solar. A paleta inteira
está em `scripts/configuracao.gd`, incluindo as cores reservadas para a futura UI.
O destaque de interação aparece na mira e na dica.
Os 60 livros da recepção são desenhados em cinco grupos por cor (MultiMesh).
Os quadros das salas e a logo da fachada usam as imagens fornecidas em `assets/`.
Os GLBs originais são instanciados sem alterar seus arquivos; a colisão do prédio
é gerada a partir da geometria. As divisórias traseiras vêm do modelo da biblioteca.
O prédio tem 44 × 28 m no arquivo Blender; no jogo, X e Z usam escala 0,5
para encaixar no terreno de 22 × 14 m, mantendo a altura original. A prévia
em `scenes/paisagismo.tscn` usa a mesma escala e o mesmo modelo.
Não há materiais emissivos ou efeitos pesados. A física usa GodotPhysics3D.

O polimento adiciona uma vista da fachada no menu, ícone da janela, instruções
de controle e detalhes chapados nas bordas do tapete, sem acrescentar luzes ou efeitos
pesados. A exportação inclui os modelos e as árvores posicionadas na cena opcional
de paisagismo para que também funcionem no EXE.

## Validação da entrega

Validado com Godot 4.7.2 em Compatibility: cliques reais no menu, pausa e retomada,
pontuações independentes, conclusão única, exploração após o resultado e reinício.
O executável Windows foi aberto e o pacote embutido foi validado separadamente,
incluindo os três JSONs, os sprites/gráficos e a conclusão de uma partida.
Na atualização com 45 questões, foram conferidas as quinze funções desenhadas,
os quinze cálculos de probabilidade, a retomada do questionário e o resultado 45/45.
Os 25 GLBs também foram verificados quanto à estrutura, materiais e quantidade
de malhas. As placas dessas referências não incluem texto.
O desempenho em notebook com GPU integrada ainda depende de teste no aparelho.

Engine: [Godot Engine](https://godotengine.org/), sob [licença MIT](https://godotengine.org/license/).
