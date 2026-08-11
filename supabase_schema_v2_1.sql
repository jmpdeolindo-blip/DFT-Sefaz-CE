-- =====================================================================
-- Coletor de Demanda SEFAZ-CE — v2
-- Schema para o Supabase (novas tabelas, independentes da v1)
--
-- Como usar:
--   1) Acesse o seu projeto em https://app.supabase.com
--   2) Vá em "SQL Editor" -> "New query"
--   3) Cole todo este arquivo e clique em "Run"
--
-- Isso cria três tabelas:
--   - coleta_demanda_v2         -> uma linha por respondente OPERACIONAL (payload completo em JSON)
--   - coleta_demanda_linhas_v2  -> uma linha por PROCESSO respondido (formato "long", bom para BI/Excel)
--   - coleta_gestao_v2          -> uma linha por respondente da camada de GESTÃO
--                                  (Coordenador / Orientador da Célula — diagnóstico de
--                                  Span & Layers e produtividade, sem processos individuais)
--
-- Todas as tabelas têm RLS (Row Level Security) habilitado, com uma
-- política que permite apenas INSERT para o público (chave anônima do
-- formulário). Ninguém consegue LER, ALTERAR ou EXCLUIR dados usando a
-- anon key publicada no HTML — apenas gravar novas respostas. Consultas
-- (leitura/exportação) devem ser feitas com a chave "service_role" ou
-- diretamente no painel do Supabase (Table editor / SQL editor).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Tabela de respostas (uma linha por respondente)
-- ---------------------------------------------------------------------
create table if not exists public.coleta_demanda_v2 (
  id uuid primary key,
  unidade text,
  versao_coletor text,
  nome text,
  coordenadoria text,
  celula text,
  nucleo text,
  cargo text,
  payload_json jsonb,
  enviado_em timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.coleta_demanda_v2 is 'Coletor de Demanda SEFAZ-CE v2 — uma linha por respondente, com o payload completo em JSON.';

create index if not exists idx_coleta_demanda_v2_nucleo on public.coleta_demanda_v2 (nucleo);
create index if not exists idx_coleta_demanda_v2_enviado_em on public.coleta_demanda_v2 (enviado_em);

alter table public.coleta_demanda_v2 enable row level security;

drop policy if exists "coleta_demanda_v2_insert_publico" on public.coleta_demanda_v2;
create policy "coleta_demanda_v2_insert_publico"
  on public.coleta_demanda_v2
  for insert
  to anon
  with check (true);

-- ---------------------------------------------------------------------
-- 2) Tabela de linhas estruturadas (uma linha por PROCESSO respondido)
--    Formato "long" — cada linha é um processo de um respondente,
--    facilitando análise em BI/Excel/planilhas.
-- ---------------------------------------------------------------------
create table if not exists public.coleta_demanda_linhas_v2 (
  id bigint generated always as identity primary key,
  resposta_id uuid references public.coleta_demanda_v2 (id) on delete cascade,
  unidade text,
  nome text,
  coordenadoria text,
  celula text,
  nucleo text,
  cargo text,
  carga_horaria_semanal numeric,
  plantao text,
  regime_plantao text,
  cobertura_processos_exaustiva text,
  macroprocesso text,
  processo text,
  processo_complementar text,
  modo_medicao text,
  complexidade_elegivel text,
  avaliar_complexidade text,
  executa text,
  volume_mes numeric,
  tempo_horas_por_processo numeric,
  frequencia_unidade text,
  frequencia_quantidade numeric,
  tempo_horas_por_execucao numeric,
  complexidade_baixa_volume_mes numeric,
  complexidade_baixa_tempo numeric,
  complexidade_media_volume_mes numeric,
  complexidade_media_tempo numeric,
  complexidade_alta_volume_mes numeric,
  complexidade_alta_tempo numeric,
  horas_mes_estimadas numeric,
  tem_sazonalidade text,
  volume_jan numeric, volume_fev numeric, volume_mar numeric, volume_abr numeric,
  volume_mai numeric, volume_jun numeric, volume_jul numeric, volume_ago numeric,
  volume_set numeric, volume_out numeric, volume_nov numeric, volume_dez numeric,
  comentario text,
  enviado text,
  enviado_em timestamptz,
  data_coleta date,
  versao_coletor text,
  created_at timestamptz not null default now()
);

comment on table public.coleta_demanda_linhas_v2 is 'Coletor de Demanda SEFAZ-CE v2 — uma linha por processo respondido (formato long).';

create index if not exists idx_coleta_demanda_linhas_v2_resposta on public.coleta_demanda_linhas_v2 (resposta_id);
create index if not exists idx_coleta_demanda_linhas_v2_nucleo on public.coleta_demanda_linhas_v2 (nucleo);
create index if not exists idx_coleta_demanda_linhas_v2_processo on public.coleta_demanda_linhas_v2 (processo);

alter table public.coleta_demanda_linhas_v2 enable row level security;

drop policy if exists "coleta_demanda_linhas_v2_insert_publico" on public.coleta_demanda_linhas_v2;
create policy "coleta_demanda_linhas_v2_insert_publico"
  on public.coleta_demanda_linhas_v2
  for insert
  to anon
  with check (true);

-- ---------------------------------------------------------------------
-- 3) Tabela de respostas da camada de GESTÃO (Coordenador / Orientador
--    da Célula) — diagnóstico de Span & Layers e produtividade.
--    Uma linha por respondente; sem tabela "linhas" associada, pois não
--    há processos individuais nesta camada (por desenho metodológico).
-- ---------------------------------------------------------------------
create table if not exists public.coleta_gestao_v2 (
  id uuid primary key,
  unidade text,
  versao_coletor text,
  nome text,
  coordenadoria text,
  celula text,
  nucleo text,          -- para respostas de gestão, armazena o código da Célula (Orientador) ou da Coordenadoria (Coordenador)
  cargo text,           -- 'Coordenador' ou 'Orientador da Célula'
  subordinados_diretos numeric,
  subordinados_indiretos numeric,
  senioridade_igual text,
  backup_formal text,
  heterogeneidade_funcoes text,
  tempo_pessoas_pct numeric,
  tempo_decisao_pct numeric,
  tempo_operacao_pct numeric,
  tempo_admin_pct numeric,
  likert_clareza numeric,
  likert_decisao numeric,
  likert_interfaces numeric,
  likert_ferramentas numeric,
  likert_padronizacao numeric,
  likert_foraescopo numeric,
  likert_equilibrio numeric,
  likert_comentario text,
  adequacao_equipe text,
  funcoes_equivalentes text,
  funcoes_equivalentes_quais text,
  gaps_senioridade text,
  gaps_senioridade_detalhe text,
  enviado text,
  enviado_em timestamptz,
  data_coleta date,
  payload_json jsonb,
  created_at timestamptz not null default now()
);

comment on table public.coleta_gestao_v2 is 'Coletor de Demanda SEFAZ-CE v2 — diagnóstico de gestão (Span & Layers e produtividade) para Coordenadores e Orientadores de Célula.';

create index if not exists idx_coleta_gestao_v2_nucleo on public.coleta_gestao_v2 (nucleo);
create index if not exists idx_coleta_gestao_v2_cargo on public.coleta_gestao_v2 (cargo);
create index if not exists idx_coleta_gestao_v2_enviado_em on public.coleta_gestao_v2 (enviado_em);

alter table public.coleta_gestao_v2 enable row level security;

drop policy if exists "coleta_gestao_v2_insert_publico" on public.coleta_gestao_v2;
create policy "coleta_gestao_v2_insert_publico"
  on public.coleta_gestao_v2
  for insert
  to anon
  with check (true);

-- =====================================================================
-- Fim do schema. Depois de rodar este script, o formulário HTML já
-- pode gravar respostas nestas três tabelas usando a URL e a chave
-- publicável (anon/publishable key) do projeto, que já estão embutidas
-- no arquivo index.html.
-- =====================================================================
