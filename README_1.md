# Coletor de Demanda — SEFAZ-CE (v2)

Formulário único (`index.html`) para coleta de dados de esforço por processo, cobrindo os 17 núcleos mapeados nesta etapa (todas as coordenadorias/células, exceto **Postos Fiscais**, que permanece fora de escopo). O arquivo é autocontido (HTML + CSS + JS em um único arquivo) e grava as respostas diretamente no Supabase.

## 1. Publicar no GitHub Pages

1. Crie um repositório novo (pode ser público ou privado, desde que o GitHub Pages esteja disponível no plano).
2. Suba o arquivo `index.html` para a raiz do repositório (mantenha o nome `index.html` para que o GitHub Pages sirva a página automaticamente na URL raiz).
3. No repositório, vá em **Settings → Pages**, em "Source" selecione a branch (`main`) e a pasta `/ (root)`, salve.
4. Em alguns minutos o formulário estará disponível em `https://<seu-usuario>.github.io/<repositorio>/`.
5. Distribua esse link para os núcleos responderem.

Não é necessário nenhum outro arquivo, build step ou configuração adicional — o `index.html` já contém a URL e a chave pública (anon/publishable key) do projeto Supabase.

## 2. Criar as tabelas no Supabase

O formulário grava em três tabelas novas (independentes da v1, para não misturar esquemas):

- `coleta_demanda_v2` — uma linha por respondente **operacional** (núcleo), com o payload completo em JSON.
- `coleta_demanda_linhas_v2` — uma linha por processo respondido (formato "long", bom para BI/Excel).
- `coleta_gestao_v2` — uma linha por respondente da **camada de gestão** (Coordenador / Orientador da Célula) — ver seção 5.

Passos:

1. Acesse `https://app.supabase.com`, abra o projeto (`bbksesebdayphpcxsczx`).
2. Vá em **SQL Editor → New query**.
3. Cole o conteúdo do arquivo `supabase_schema_v2.sql` (incluído nesta entrega) e clique em **Run**.
4. Pronto — as tabelas são criadas com RLS (Row Level Security) habilitado e uma política que permite **apenas INSERT** para a chave pública usada pelo formulário. Ninguém consegue ler, alterar ou excluir dados com a chave publicada no HTML; para consultar os dados, use o Table editor do Supabase (com sua conta) ou a chave `service_role` em um ambiente seguro.

Se você já rodou o `supabase_schema_v2.sql` anterior (sem a tabela de gestão), pode rodar o arquivo novo sem problema: os comandos usam `create table if not exists` e `drop policy if exists`, então não duplicam nem quebram o que já existia — só adicionam a tabela `coleta_gestao_v2`.

## 3. Testar antes de divulgar

Depois de publicar, abra o link do GitHub Pages e faça dois testes completos: um como cargo operacional (ex.: Servidor Auditor de um núcleo) e outro como cargo de gestão (Coordenador ou Orientador da Célula — ver seção 5). Clique em **"Concluir e enviar respostas"** em cada um e confira no Supabase (Table editor) se a linha apareceu em `coleta_demanda_v2`/`coleta_demanda_linhas_v2` (teste operacional) e em `coleta_gestao_v2` (teste de gestão). Pode excluir essas linhas de teste antes de divulgar oficialmente.

Se o envio falhar (por exemplo, sem internet ou com bloqueio de rede), o formulário **não** mostra a tela de sucesso — ele exibe uma mensagem de erro clara e mantém a resposta salva no navegador (localStorage), para que o usuário possa tentar novamente sem perder o que já preencheu. Isso foi feito de propósito, para garantir que uma resposta só seja considerada "enviada" quando o Supabase realmente confirmar o registro.

## 4. O que mudou nesta versão (v2)

- Todos os 17 núcleos mapeados foram incluídos no mesmo arquivo HTML (antes só NUSEQ estava carregado, em versão de teste).
- As perguntas agora são organizadas por **processo** (não mais por subprocesso), com uma caixa explicando o que cada perfil/cargo faz naquele processo, quando o mapa de perfis do núcleo já foi validado pela área.
- O botão de "executo / não executo" o processo foi redesenhado como um interruptor de dois estados sempre visíveis.
- Três formas de medir esforço: quantidade/mês + tempo médio, frequência (para atividades sem contagem mensal natural) e, opcionalmente, avaliação por grau de complexidade (baixa/média/alta) nos processos de fiscalização/monitoramento em que isso faz sentido.
- **Complexidade é opcional, não obrigatória**: cada processo elegível mostra primeiro a pergunta "Deseja avaliar este processo por grau de complexidade?". Se "Não", o usuário informa apenas uma quantidade e um tempo médio padrão. Se "Sim", aparecem os três blocos (baixa/média/alta) e a regra de validação é:
  - um nível **totalmente em branco** é tratado como "não se aplica" (conta como zero, sem erro);
  - um nível **parcialmente preenchido** (só quantidade ou só tempo) é erro — pede para completar o outro campo;
  - se **nenhum** dos três níveis for preenchido enquanto "Sim" estiver selecionado, é erro — pede para preencher ao menos um nível ou trocar para "Não".
- Sazonalidade agora é uma pergunta binária (Sim/Não) antes de abrir a grade de 12 meses, em vez de mostrar a grade sempre.
- Envio real ao Supabase (antes era só localStorage + exportação CSV/JSON local).
- **Camada de gestão (Coordenador / Orientador da Célula)** tratada separadamente da camada operacional, com um diagnóstico próprio em vez de perguntas por processo — ver seção 5.

## 5. Camada de gestão: Coordenador e Orientador da Célula

Coordenador e Orientador da Célula não aparecem mais como opção de cargo dentro de um núcleo (antes apareciam junto com Auditor/Supervisor/Colaborador em alguns núcleos, o que não fazia sentido — essas duas funções atuam no nível da célula ou da coordenadoria como um todo, não em um núcleo específico).

Para responder como uma dessas funções, o fluxo é:

- **Orientador da Célula**: selecione a Coordenadoria e a Célula normalmente, e no campo **Núcleo** escolha a opção "— Atuo na Célula (Orientador da Célula, sem núcleo específico) —", no final da lista.
- **Coordenador**: selecione a Coordenadoria e, no campo **Célula**, escolha a opção "— Atuo na Coordenadoria (Coordenador, sem célula específica) —", no final da lista. O campo Núcleo desaparece automaticamente, pois não se aplica.

Ao selecionar o cargo correspondente, a seção 2 do formulário muda de "Processos" para **"Diagnóstico de gestão"** — um questionário mais curto (até ~15 minutos), com 4 blocos, seguindo a metodologia de Span & Layers e Produtividade de Pessoal (gestores têm atividades predominantemente skill-based, então perguntas de censo por processo e tempo médio não funcionam bem para essa camada):

1. **Estrutura e escopo de gestão** — número de subordinados diretos/indiretos, existência de liderado com senioridade igual, backup formal, heterogeneidade das funções sob gestão.
2. **Alocação de tempo por macro-categoria** (percentual, soma ≈ 100%) — gestão de pessoas, gestão de processos e decisão, execução operacional direta, atividades administrativas e rotina.
3. **Percepção sobre produtividade e barreiras** (Likert 1-5) — sete afirmações (clareza de papéis, simplificação de decisão, eficiência de interfaces, ferramentas adequadas, padronização do trabalho da equipe, atividades fora do escopo, equilíbrio operação/gestão) + campo aberto opcional.
4. **Percepção sobre o dimensionamento da própria equipe** — adequação do número de liderados, funções equivalentes em outras áreas, gaps de senioridade percebidos.

A seção 3 ("Cobertura dos processos mapeados") não aparece para esses cargos, pois não se aplica ao diagnóstico de gestão. As respostas são gravadas na tabela `coleta_gestao_v2` (separada das tabelas operacionais) e também podem ser exportadas em CSV/JSON com campos próprios.

**Conteúdo conservador, por decisão explícita**: os cinco itens de cada bloco (e o texto de apoio do bloco 2) foram fundamentados no Regimento da Sefaz (Decreto nº 36.318/2024) — especificamente no Art. 108 ("planejar, dirigir, coordenar e avaliar... orientar a execução das ações estratégicas... promover a integração dos processos") e nos Art. 119-121 (Comitês Táticos da Administração Fazendária, onde o Coordenador e os Orientadores de Célula homologam metas, monitoram resultados e dirimem conflitos de competência). Não incluí nenhuma atividade técnica específica de núcleo/setor nessas funções — só o que está claramente estabelecido no Regimento como atribuição de chefia. Se depois da aplicação a área quiser aprofundar com perguntas mais específicas por coordenadoria/célula, me avise para eu ajustar.

**Assunção que fiz e que vale confirmar**: você mencionou que, no nível de Orientador da Célula, pode haver pessoas que o auxiliam diretamente (Auditor, Colaborador Terceirizado) sem estarem ligadas a um núcleo específico. Por ora, não criei opções de cargo para esse cenário — apenas Coordenador e Orientador da Célula têm o fluxo de gestão. Se houver, de fato, pessoas nessa situação (reportando à célula ou à coordenadoria, sem núcleo), me diga e eu adiciono os cargos correspondentes com o fluxo adequado (provavelmente o diagnóstico operacional por processo, não o de gestão, já que são cargos de execução).

## 6. Núcleos com mapa de perfis ainda não validado

Para os núcleos abaixo, a área ainda não confirmou qual perfil/cargo executa cada processo (planilhas originais sem a coluna de confirmação preenchida). Por isso, o formulário mostra **todos os processos mapeados do núcleo para qualquer cargo selecionado**, com um aviso amarelo no topo da seção de processos, em vez de filtrar por perfil:

- NUMIT
- NUPAF
- NUSEC
- NUMES
- NUSAL
- NUSCOB

Quando esses mapas forem validados pela área, me avise para que eu atualize o arquivo com os perfis corretos por cargo (o que também passará a filtrar os processos por cargo nesses núcleos, como já ocorre nos demais).

## 7. Pendências de redação identificadas (NUMAT)

Ao estruturar a planilha do NUMAT, algumas linhas estavam marcadas como "Ajustar" ou sem confirmação — não foram incluídas no mapa de processos do formulário, mas ficam registradas aqui para revisão da área:

- **Credenciamento e recadastramento** — "Coletar e registrar termos de acordo e cadastramentos temporários": redação sugerida pela área seria "Aprovar termos de acordo"; o item "temporário" pode ser retirado, pois já consta em outro subprocesso.
- **Credenciamento e recadastramento** — "Operacionalizar etapas administrativas de credenciamento (planilha, e-mail, AR físico sem DTE)": essas etapas não seriam do credenciamento, e sim das modalidades de ciência de contribuintes autuados (DTE, AR, pessoal, edital, eletrônica).
- **Credenciamento e recadastramento** — "Processar termo de acordo no SIPAD (...)": o nome correto do sistema seria SIPAJ, não SIPAD.
- **Processos Tramita e atendimento** — "Processar restituição de transportadora via Tramita (até R$ 5.000 UMUF; até R$ 30.000 NUMAT; acima → CECOM)": trocar UMUF por UFIRCES e CECOM por CECON.
- **Diligência e intimação de transportadoras** — "Lavrar Auto de Infração por descumprimento de Termo de Acordo ou falta de obrigação acessória": linha sem confirmação preenchida na planilha original.
- **Monitoramento de transportadoras** — "Acompanhar metas e resultados de monitoramento no painel de transportadoras (Tableau)": linha sem confirmação preenchida na planilha original.

## 8. Outras decisões de estruturação (para revisão)

- **NUPAM**: a planilha original tinha duas abas de processos ("Processos" e "Processos_novo"); foi usada exclusivamente a aba "Processos_novo", que é a versão validada e substitui a primeira.
- **Descrições de grau de complexidade** (baixa/média/alta) são genéricas, adaptadas de critérios usuais de administrações fazendárias (porte do contribuinte, volume documental, indícios de sonegação/histórico de infrações) — não são específicas de cada núcleo. Vale revisar com as áreas se quiserem descrições mais específicas por processo.
- Processos marcados como "Não" nas planilhas de validação foram excluídos do formulário (não aparecem como pergunta).
- **Postos Fiscais** permanece fora do escopo desta etapa, por instrução explícita; o núcleo aparece na lista de seleção apenas para navegação, mas o formulário informa que o mapa ainda está em preparação caso seja selecionado.

## 9. Arquivos desta entrega

- `index.html` — o formulário completo, pronto para publicar no GitHub Pages.
- `supabase_schema_v2.sql` — script para criar as tabelas `coleta_demanda_v2` e `coleta_demanda_linhas_v2` no Supabase.
- `README.md` — este guia.
