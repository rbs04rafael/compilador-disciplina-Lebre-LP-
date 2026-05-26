# Explicação do Último Commit: Suporte a Blocos e Escopos

No último commit (mensagem `"bloco"`), foram implementadas as funcionalidades para suportar a criação de **blocos de código delimitados por chaves `{ }`** e a **resolução de escopos de variáveis**. 

Abaixo estão os detalhes de cada alteração:

### 1. Analisador Léxico (`lexico.l`)
- **Reconhecimento de chaves:** Foram adicionados os caracteres `{` e `}` na regra de identificação de símbolos literais (`[-+*/()=;><!{}]`). Agora o analisador léxico consegue identificar o início e o fim de um bloco no código-fonte e passar essa informação de forma correspondente para o sintático.

### 2. Estrutura da Tabela de Símbolos (`sintatico.y`)
- **De mapa global para vetor de escopos:** A antiga variável global `map<string, info_var> tabela_simbolos` foi substituída por `vector<map<string, info_var>> tabela_escopos`. 
- **O que isso significa:** Agora a tabela de símbolos funciona como uma pilha de escopos (representada pelo `vector`). O índice `0` será o escopo global. Quando o analisador entra em um novo bloco, um novo mapa (escopo local) é adicionado à pilha.

### 3. Funções Auxiliares de Gerenciamento de Variáveis
A manipulação da tabela de símbolos que era feita diretamente nas regras da gramática foi encapsulada em funções em C++ para lidar com a nova estrutura de dados (vetor de mapas):
- **`declarar_variavel(string nome, string tipo)`:** 
  Olha apenas para o **topo da pilha** (`tabela_escopos.back()`). Se a variável já existir no escopo local, dispara o erro de "variável já declarada nesse escopo". Caso contrário, gera uma variável temporária, adiciona a declaração na string de código alvo em C, e salva as informações no escopo atual.
- **`consultar_variavel(string nome)`:**
  Procura por uma variável percorrendo os mapas do vetor de **trás para frente** (do escopo mais interno, até o escopo global). A primeira ocorrência que encontrar é a retornada (permitindo o *shadowing* de variáveis). Se a busca terminar e não encontrar nada, emite o erro de "variável não declarada".

### 4. Regras da Gramática para Blocos (Sintático)
- **Modificação na regra `LISTA_DEC`:** A gramática foi expandida para conseguir processar os blocos `{ LISTA_DEC }`. Ao encontrar um `{`, o compilador:
  - Salva o estado atual da variável geradora de declarações em C (`declaracoes_anterior`).
  - Limpa a string de `declaracoes`.
  - Empilha um novo mapa (`map<string, info_var>`) vazio na lista de escopos (`tabela_escopos.push_back`).
  - Incrementa o contador de nível de escopo.
- **Ao encontrar o fechamento `}`:**
  - Gera a tradução daquele bloco no formato de um bloco C `{\n ... \n}` usando as declarações traduzidas que aconteceram lá dentro.
  - Restaura as declarações do escopo "pai" (`declaracoes = declaracoes_anterior`).
  - Desempilha o escopo local da lista de variáveis ativas (`tabela_escopos.pop_back()`).

### 5. Outros Ajustes
- Foi adicionado a diretiva `#include <vector>` no sintático para suportar a nova estrutura de dados.
- Modificação no `main()` do compilador (`sintatico.y`) para garantir que o vetor já comece possuindo o seu escopo global (posição zero) antes de iniciar o `yyparse()`.
- Um pequeno ajuste em um arquivo de teste (`01_soma.foca`).