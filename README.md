# Vertem Workshop — Data Prep & Auto CDC no Databricks

Workshop hands-on para o time **Vertem** cobrindo dois módulos práticos na plataforma Databricks: **Visual Data Prep** (limpeza e enriquecimento de dados com IA) e **Auto CDC** (Change Data Capture declarativo com SCD Tipo 1 e Tipo 2).

---

## Pré-requisitos

| Item | Detalhe |
|---|---|
| Workspace Databricks | Com Unity Catalog habilitado |
| Catálogo / Schema | `vertem.workshop_dataprep` (criados previamente) |
| Compute | Serverless SQL Warehouse ou cluster com acesso ao Unity Catalog |
| Permissões | `USE CATALOG`, `USE SCHEMA`, `CREATE TABLE` no schema acima |

---

## Estrutura do Repositório

```
vertem-workshop/
├── README.md
├── visual-data-prep/                  # Módulo 1 — Visual Data Prep
│   ├── 00_setup.ipynb                 # Gera tabelas RAW com problemas de qualidade
│   ├── discovery.ipynb                # Exploração inicial dos dados
│   ├── vertem-resgates.designer.ipynb # Visual Data Prep (Designer) — fluxo no-code
│   └── metas_resgate_2025.xlsx        # Planilha de metas para upload/join
│
└── auto-cdc/                          # Módulo 2 — Auto CDC
    ├── 00_setup.ipynb                 # Cria tabela de CDC bruto (cdc_clientes_raw)
    ├── 01_insert.ipynb                # Simula novos eventos CDC (UPDATE, INSERT, DELETE)
    ├── 99-validacao.ipynb             # Consultas de validação (SCD1, SCD2, point-in-time join)
    ├── auto-cdc-pipeline.yml          # Definição da pipeline Lakeflow Declarative
    └── auto-cdc-pipeline/
        └── transformations/
            ├── 01_bronze_cdc_clientes.sql       # Streaming Table — ingestão bronze
            ├── 02_dim_cliente_scd1.sql           # AUTO CDC → SCD Tipo 1
            ├── 02_dim_cliente_scd2.sql           # AUTO CDC → SCD Tipo 2
            ├── 03_dim_cliente_scd2_track.sql     # SCD Tipo 2 com TRACK HISTORY ON
            └── 05_dim_cliente.sql                # Materialized View — visão corrente
```

---

## Módulo 1 — Visual Data Prep

### Objetivo

Demonstrar como limpar, padronizar e enriquecer dados de **fidelidade e resgate de pontos** usando o Visual Data Prep (Designer), AI Functions (`ai_classify`, `ai_summarize`) e Guardrails para detecção de PII.

### Tabelas geradas pelo `00_setup`

| Tabela | Linhas | Problemas embutidos | Campos para IA |
|---|---:|---|---|
| `clientes_b2b` | ~44 | Casing/espaços no nome, e-mail nulo, datas em 2 formatos, tipo de programa e status inconsistentes, duplicatas | `descricao_empresa` — texto livre para `ai_classify` / `ai_summarize` |
| `parceiros_resgate` | 12 | Nome/categoria/canal inconsistentes, SLA como texto, nulos | — |
| `campanhas` | ~126 | Datas em 2 formatos, status/canal inconsistentes, orçamento como texto, duplicatas | `briefing_campanha` — texto livre para `ai_summarize` |
| `resgates` | ~25.208 | FKs órfãs, pontos/quantidade inválidos, datas em 2 formatos, status/canal inconsistentes, duplicatas | `feedback_participante` — texto com PII (CPF, telefone, e-mail) para Guardrails + `ai_classify` sentimento |

### Passo a passo

1. Execute o notebook **`00_setup`** para criar as tabelas RAW no schema `vertem.workshop_dataprep`
2. (Opcional) Abra o notebook **`discovery`** para explorar os dados e entender os problemas de qualidade
3. Abra o arquivo **`vertem-resgates.designer.ipynb`** no Visual Data Prep para acompanhar o fluxo de limpeza no-code
4. Utilize a planilha **`metas_resgate_2025.xlsx`** como fonte auxiliar para joins no Designer

---

## Módulo 2 — Auto CDC (Change Data Capture)

### Objetivo

Demonstrar como aplicar **AUTO CDC** em uma pipeline Lakeflow Spark Declarative para transformar um feed de CDC append-only em dimensões SCD Tipo 1 e Tipo 2, usando SQL puro e declarativo.

### Arquitetura da pipeline

```
cdc_clientes_raw  (tabela origem, append-only)
        │
        ▼
bronze_cdc_clientes  (Streaming Table + constraints de qualidade)
        │
        ├──▶ dim_cliente_scd1        (AUTO CDC → SCD Tipo 1 — só estado atual)
        ├──▶ dim_cliente_scd2        (AUTO CDC → SCD Tipo 2 — histórico completo)
        ├──▶ dim_cliente_scd2_track  (SCD Tipo 2 + TRACK HISTORY ON segmento)
        │
        └──▶ dim_cliente             (Materialized View — clientes vigentes)
```

### Tabela de origem — `cdc_clientes_raw`

| Coluna | Tipo | Descrição |
|---|---|---|
| `cliente_id` | INT | Chave de negócio |
| `nome` | STRING | Nome do cliente |
| `cidade` | STRING | Cidade |
| `segmento` | STRING | Bronze / Prata / Ouro |
| `operacao` | STRING | INSERT, UPDATE ou DELETE |
| `ts` | TIMESTAMP | Momento do evento no sistema origem |

### Passo a passo

1. Execute o notebook **`00_setup`** para criar e popular a tabela `cdc_clientes_raw` com os 4 clientes iniciais (INSERT)
2. Abra a pipeline **`auto-cdc-pipeline`** no Databricks e execute o primeiro update — as dimensões SCD1 e SCD2 serão criadas
3. Execute o notebook **`01_insert`** para simular novos eventos:
   * UPDATE no segmento da Ana (Bronze → Prata → Ouro)
   * UPDATE na cidade do Bruno (Rio de Janeiro → Niterói)
   * INSERT de novo cliente (Elisa)
   * DELETE da Carla
4. Re-execute a pipeline para processar os novos eventos
5. Abra o notebook **`99-validacao`** para conferir:
   * Contagem de linhas nas tabelas SCD1 e SCD2
   * Histórico de versões por cliente
   * Point-in-time join (vendas × segmento na data da venda)

---

## Como usar este repositório

1. **Clone** o repositório Git para sua pasta no Workspace Databricks
2. Verifique se o catálogo `vertem` e o schema `workshop_dataprep` existem (ou crie-os)
3. Siga a ordem dos notebooks dentro de cada módulo (começando sempre pelo `00_setup`)
   > **Nota:** Todos os notebooks já possuem `USE CATALOG vertem; USE SCHEMA workshop_dataprep;` na primeira célula. Se o seu catálogo/schema for diferente, atualize essa célula antes de executar.
4. Para o módulo Auto CDC, importe a pipeline usando o arquivo `auto-cdc-pipeline.yml` ou crie manualmente apontando para a pasta `transformations/`

---

## Tecnologias utilizadas

* **Databricks Serverless** — compute sob demanda
* **Unity Catalog** — governança e catálogo unificado
* **Visual Data Prep (Designer)** — limpeza de dados no-code
* **Lakeflow Spark Declarative Pipelines** — pipelines declarativas com qualidade embutida
* **AUTO CDC** — captura de mudanças incremental (SCD Tipo 1, Tipo 2, TRACK HISTORY)
* **AI Functions** — `ai_classify`, `ai_summarize` para enriquecimento
* **Guardrails** — detecção de PII em campos de texto livre
* **Delta Lake** — formato de armazenamento com ACID e time travel
