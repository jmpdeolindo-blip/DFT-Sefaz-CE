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

**Atualização**: a assunção pendente sobre pessoas de apoio direto à célula/coordenadoria (sem núcleo específico) foi resolvida — ver seção 5b.

## 5b. Cargos de apoio à célula/coordenadoria (sem núcleo específico)

Além de Coordenador e Orientador da Célula, cada pseudo-lotação de célula/coordenadoria agora também oferece os cargos **Servidor (Auditor)** e **Colaborador (Terceirizado)**, para as pessoas que auxiliam diretamente o Coordenador/Orientador (tipicamente secretariado e apoio administrativo) sem estarem vinculadas a um núcleo específico. A seleção de Coordenadoria/Célula é a mesma da seção 5 (opção "Atuo na Coordenadoria"/"Atuo na Célula"); a diferença é o cargo escolhido no passo seguinte.

Como ainda não mapeamos as atividades desses cargos de apoio, o formulário **não tenta adivinhar processos** — em vez disso, a seção 2 muda para **"Processos que você executa"**, onde a própria pessoa cadastra os processos que realiza:

1. Clica em "➕ Adicionar processo" (pode adicionar quantos precisar).
2. Para cada processo: dá um nome curto, escreve uma breve descrição do que consiste, e escolhe como prefere informar o esforço — **quantidade por mês + tempo médio** ou **frequência** (para atividades sem contagem mensal natural, iguais às opções já usadas na camada operacional).
3. É necessário cadastrar ao menos um processo para poder enviar a resposta.

Como na camada de gestão, a seção 3 ("Cobertura dos processos mapeados") não aparece para esses cargos — não há um catálogo pré-definido para comparar. As respostas seguem para as mesmas tabelas operacionais (`coleta_demanda_v2` / `coleta_demanda_linhas_v2`), com as linhas de processo marcadas com `processo_apoio = 'SIM'` e a descrição do respondente em `descricao_processo`, para diferenciá-las dos processos do catálogo mapeado.

## 6. Núcleos com mapa de perfis ainda não validado

Para os núcleos abaixo, a área ainda não confirmou qual perfil/cargo executa cada processo (planilhas originais sem a coluna de confirmação preenchida). Por isso, o formulário mostra **todos os processos mapeados do núcleo para qualquer cargo selecionado**, com um aviso amarelo no topo da seção de processos, em vez de filtrar por perfil:

- NUMIT
- NUPAF
- NUSEC
- NUMES
- NUSAL

Quando esses mapas forem validados pela área, me avise para que eu atualize o arquivo com os perfis corretos por cargo (o que também passará a filtrar os processos por cargo nesses núcleos, como já ocorre nos demais).

**NUSCOB saiu desta lista nesta atualização**: a área respondeu a planilha de validação (confirmação de execução por subprocesso + perfis), então o núcleo passou a filtrar processos por cargo como os demais — ver seção 9.

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

## 9. Atualização de conteúdo — NUSCOB e NUMOV

Com base nas planilhas de resposta enviadas pelos núcleos:

- **NUSCOB**: passou de "não validado" para **validado**. Dos 12 processos antes listados, 2 foram removidos por terem sido confirmados como "Não executado" pela área (Ressarcimento ICMS e Restituição ICMS como processos autônomos — as atividades equivalentes de ressarcimento/restituição de ICMS ST continuam cobertas dentro do processo "Atendimento de processos (Tramita)", que foi confirmado). Os 10 processos restantes agora têm a descrição e os perfis (Servidor Auditor / Supervisor do Núcleo / Colaborador Terceirizado) redigidos a partir da planilha de resposta. O cargo "Estagiário", que constava na lista de cargos do núcleo mas não aparece em nenhuma linha confirmada da planilha, foi removido — seguindo o mesmo padrão adotado nos demais núcleos validados. Como em todos os núcleos, "Coordenador" e "Orientador da Célula" não entram nos perfis do núcleo (essas funções respondem pelo fluxo de gestão da célula/coordenadoria — ver seção 5), mesmo tendo aparecido na planilha de resposta como perfis de alguns subprocessos.
- **NUMOV**: manteve a mesma estrutura e os mesmos 7 processos; a única mudança foi a inclusão do subprocesso "Atender SAC Sistema SIGA - N1" (perfil Servidor Auditor) dentro do processo já existente "Correção de erros", cuja descrição e perfil de Auditor foram atualizados para refletir essa atividade.

Nenhuma das duas atualizações exigiu mudança na lógica do formulário — foi só conteúdo (descrição/perfis/processos), dentro da estrutura já existente.

## 10. Pergunta de plantão/escala — restrita à COFIT

Na reunião de apresentação do formulário, o Coordenador da COMFI (Jorge Saboia) apontou que a pergunta de plantão/escala confundia os auditores da COMFI, que alternam entre trabalho remoto e presencial (regime híbrido) — regime esse que não tem relação com a pergunta. Como a pergunta é relevante principalmente para quem cumpre escala em posto fiscal (COFIT), o formulário foi ajustado:

- A pergunta "Trabalha em regime de plantão / escala de posto fiscal?" só aparece na Identificação quando a **Coordenadoria selecionada é a COFIT**; para a COMFI ela fica oculta e não é solicitada nem validada.
- Foi adicionado um texto de apoio junto à pergunta esclarecendo que ela **não se refere ao regime híbrido de teletrabalho/presencial**, para o caso de haver também auditores em regime híbrido dentro da COFIT.
- O campo único de "regime de plantão" (12x36 / 24x72 / Escala administrativa / Outro) foi substituído por **dois campos**, com base nas escalas e turnos efetivamente praticados nos postos fiscais:
  - **Escala (dias)**: 5x10, 5x9, 5x5, Horário comercial, ou Outro (com campo de texto livre).
  - **Turno / plantão (horário)**: 8x8 (revezamento 24h), 12x12, Plantão diurno estendido (ex.: 7h–22h) — Mucuripe, Entrada escalonada (7h/8h/10h) — Mucuripe, Horário comercial, ou Outro (com campo de texto livre).

No banco de dados, a tabela `coleta_demanda_linhas_v2` ganhou as colunas `escala_dias` e `turno_plantao` (a coluna antiga `regime_plantao` foi mantida na tabela, mas deixou de ser usada). O `supabase_schema_v2.sql` desta entrega já inclui os comandos `alter table ... add column if not exists` para atualizar um banco criado em versão anterior sem perda de dados.

Por segurança, a chave de rascunho salvo no navegador (localStorage) **não foi alterada** nesta atualização — só o rótulo de versão exibido/enviado ao Supabase avançou (agora v2.3) — para não descartar rascunhos de quem já começou a preencher o formulário publicado. Um rascunho antigo com a pergunta de plantão respondida no formato anterior é migrado automaticamente ao abrir o formulário; apenas o valor específico do campo antigo de regime (ex.: "12x36") não é recuperado, sendo necessário reselecioná-lo nos dois novos campos, caso se aplique.

## 12. NUFIT removido do formulário

Em reunião recente com a equipe da COFIT, ficou claro que as atividades da NUFIT são muito semelhantes às dos Postos Fiscais — por isso, a NUFIT sairá deste formulário e será incorporada ao futuro mapeamento de Postos Fiscais (ainda fora de escopo, como já era o caso dos Postos Fiscais).

- A NUFIT foi removida da célula CEMOT (que agora só lista o NUMIT) e do catálogo de núcleos do formulário. Os 8 processos antes mapeados para a NUFIT saíram do total (de 168 para **160** processos operacionais no formulário).
- **Não há qualquer alteração de estrutura no Supabase**: o núcleo é gravado como texto livre (`nucleo`), sem restrição a uma lista fixa (enum/FK) — remover uma opção do formulário não exige nenhuma migração de schema. Dados já enviados anteriormente por respondentes da NUFIT permanecem intactos no banco, só não é mais possível selecioná-la para novas respostas.
- Se alguém tiver um rascunho salvo no navegador com NUFIT selecionada, o formulário recai automaticamente para outro núcleo válido da mesma célula (NUMIT) ao recarregar — sem erro, mas a pessoa precisa reconferir/reselecionar o núcleo e o cargo antes de continuar.

## 13. Arquivos desta entrega

- `index.html` — o formulário completo, pronto para publicar no GitHub Pages.
- `supabase_schema_v2.sql` — script para criar/atualizar as tabelas `coleta_demanda_v2`, `coleta_demanda_linhas_v2` e `coleta_gestao_v2` no Supabase.
- `README.md` — este guia.
