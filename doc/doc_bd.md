# Modelo ER — Portal B2B

## Visão Geral

O banco de dados utiliza o schema `portal_b2b` no PostgreSQL.

**Roles:**

| Role | Tipo | Permissões |
|------|------|------------|
| `db_portal_b2b` | Admin/DDL | Owner do schema, DDL, DML |
| `svc_portal_b2b` | Aplicação | SELECT, INSERT, UPDATE, DELETE (sem CREATE) |

> **Nota:** `svc_portal_b2b` não pode criar ou alterar objetos. Toda migração DDL deve ser executada como `db_portal_b2b`.

## Entidades

### 1. empresa

Representa qualquer organização cadastrada. CNPJ e e-mail únicos.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK, default `gen_random_uuid()` |
| `razao_social` | VARCHAR(255) | NOT NULL |
| `nome_fantasia` | VARCHAR(255) | NULL |
| `cnpj` | CHAR(14) | NOT NULL, UNIQUE |
| `email` | VARCHAR(150) | NOT NULL, UNIQUE |
| `telefone` | VARCHAR(20) | NULL |
| `status` | VARCHAR(20) | NOT NULL, default `'ATIVO'` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 1.1. usuario

Usuários vinculados a uma empresa.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_id` | UUID | FK → `empresa(id)` |
| `nome` | VARCHAR(150) | NOT NULL |
| `email` | VARCHAR(150) | NOT NULL, UNIQUE |
| `senha_hash` | TEXT | NOT NULL |
| `telefone` | VARCHAR(20) | NULL |
| `status` | VARCHAR(20) | NOT NULL, default `'ATIVO'` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 2. perfil

Papéis disponíveis no sistema. Valores fixos inseridos via seed.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `nome` | VARCHAR(50) | NOT NULL, UNIQUE |

**Valores:** `FORNECEDOR`, `COMPRADOR`, `TRANSPORTADORA`

---

### 3. empresa_perfil

Associação N:N entre empresa e perfil (RN-USER-02).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `empresa_id` | UUID | PK, FK → `empresa(id)` ON DELETE CASCADE |
| `perfil_id` | UUID | PK, FK → `perfil(id)` ON DELETE CASCADE |

---

### 4. endereco

Endereços vinculados a empresas. Usado como origem em fornecimentos e destino em demandas.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_id` | UUID | FK → `empresa(id)` |
| `cidade` | VARCHAR(100) | NOT NULL |
| `estado` | CHAR(2) | NOT NULL |
| `cep` | CHAR(8) | NOT NULL |
| `latitude` | DECIMAL(9,6) | NULL |
| `longitude` | DECIMAL(9,6) | NULL |

---

### 5. produto

Catálogo genérico de produtos. **Sem preço e sem quantidade** (RN-PROD-01/02).  
Pertence ao serviço de negociação/mercado — desacoplado de `produtos_produto`.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `nome` | VARCHAR(150) | NOT NULL |
| `categoria` | VARCHAR(100) | NULL |
| `unidade_medida` | VARCHAR(20) | NULL |
| `tipo_transporte` | VARCHAR(50) | NULL — RN-PROD-03 |
| `ativo` | BOOLEAN | NOT NULL, default `TRUE` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 6. fornecimento

Oferta de um fornecedor para um produto (RN-FORN-01/02/05).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_fornecedor_id` | UUID | FK → `empresa(id)` |
| `produto_id` | UUID | FK → `produto(id)` |
| `endereco_origem_id` | UUID | FK → `endereco(id)` |
| `preco_unitario` | DECIMAL(18,4) | NOT NULL, > 0 |
| `quantidade_disponivel` | DECIMAL(18,4) | NOT NULL, >= 0 — RN-FORN-04 |
| `ativo` | BOOLEAN | NOT NULL, default `TRUE` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 7. demanda

Interesse de compra de um comprador (RN-DEM-01..05).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_comprador_id` | UUID | FK → `empresa(id)` |
| `produto_id` | UUID | FK → `produto(id)` |
| `endereco_destino_id` | UUID | FK → `endereco(id)` |
| `quantidade_desejada` | DECIMAL(18,4) | NOT NULL, > 0 |
| `is_recorrente` | BOOLEAN | NOT NULL, default `FALSE` |
| `data_proxima_geracao` | DATE | NULL — obrigatório se recorrente (RN-DEM-03) |
| `status` | VARCHAR(30) | NOT NULL, default `'ABERTA'` — RN-DEM-05 |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

> **Constraint:** `is_recorrente = TRUE` exige `data_proxima_geracao IS NOT NULL`.

---

### 8. processo_negociacao

Gerencia a negociação (RN-MERC-01/02, RN-NEG-01..04).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `produto_id` | UUID | FK → `produto(id)` |
| `modo` | VARCHAR(20) | NOT NULL — `direto`, `leilao_direto`, `leilao_reverso` |
| `status` | VARCHAR(20) | NOT NULL, default `'ABERTO'` |
| `data_inicio` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `data_fim` | TIMESTAMPTZ | NULL |
| `valor_reserva` | DECIMAL(18,4) | NULL |

**Modos (RN-MERC-01):**

| Condição | Modo |
|----------|------|
| oferta = demanda | `direto` |
| demanda > oferta | `leilao_direto` |
| oferta > demanda | `leilao_reverso` |

---

### 9. lance

Propostas feitas durante um processo (RN-NEG-02/03).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `processo_id` | UUID | FK → `processo_negociacao(id)` |
| `empresa_id` | UUID | FK → `empresa(id)` |
| `valor_unitario` | DECIMAL(18,4) | NOT NULL, > 0 |
| `quantidade` | DECIMAL(18,4) | NOT NULL, > 0 |
| `data_lance` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 10. pedido

Formaliza a compra após negociação (RN-PED-01..04).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `processo_id` | UUID | FK → `processo_negociacao(id)` |
| `empresa_comprador_id` | UUID | FK → `empresa(id)` |
| `empresa_fornecedor_id` | UUID | FK → `empresa(id)` |
| `fornecimento_id` | UUID | FK → `fornecimento(id)` — RN-PED-02 |
| `frete_selecionado_id` | UUID | FK → `frete_selecionado(id)`, NULL inicial |
| `valor_comissao` | DECIMAL(18,4) | NULL — RN-PED-04 |
| `valor_total` | DECIMAL(18,4) | NOT NULL, > 0 |
| `status` | VARCHAR(20) | NOT NULL, default `'PENDENTE'` — RN-PED-03 |
| `data_pedido` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

> `frete_selecionado_id` é NULL na criação. Preenchido após seleção do frete.  
> Referência circular resolvida via `ALTER TABLE` após criação de `frete_selecionado`.

---

### 11. item_pedido

Itens que compõem o pedido.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)` |
| `produto_id` | UUID | FK → `produto(id)` |
| `fornecimento_id` | UUID | FK → `fornecimento(id)` |
| `quantidade` | DECIMAL(18,4) | NOT NULL, > 0 |
| `valor_unitario` | DECIMAL(18,4) | NOT NULL, > 0 |

---

### 12. solicitacao_frete

Gerada a partir do pedido (RN-LOG-01/02).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)` |
| `tipo_transporte` | VARCHAR(50) | NOT NULL |
| `status` | VARCHAR(30) | NOT NULL, default `'AGUARDANDO'` |
| `data_criacao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 13. cotacao_frete

Propostas de frete por transportadoras (RN-LOG-03, RN-TRANS-04).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `solicitacao_id` | UUID | FK → `solicitacao_frete(id)` |
| `transportadora_id` | UUID | FK → `empresa(id)` |
| `valor` | DECIMAL(18,4) | NOT NULL, > 0 |
| `prazo` | INTEGER | NOT NULL, > 0 — dias úteis |
| `data_cotacao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

> `prazo` definido como `INTEGER` (dias úteis) para permitir ordenação e comparação.

---

### 14. frete_selecionado

Frete escolhido para o pedido (RN-LOG-04).

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)`, UNIQUE — 1 frete por pedido |
| `cotacao_id` | UUID | FK → `cotacao_frete(id)` |
| `data_selecao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

## Relacionamentos

```
empresa ──────────────── empresa_perfil ─────── perfil
empresa ──────────────── usuario
empresa ──────────────── endereco
empresa ──────────────── fornecimento ─────────── produto
empresa ──────────────── demanda ──────────────── produto
empresa ──────────────── lance ────────────────── processo_negociacao
processo_negociacao ──── pedido ◄─────────────── frete_selecionado
pedido ───────────────── item_pedido
pedido ───────────────── solicitacao_frete ─────► cotacao_frete
                                                        │
                                              frete_selecionado ◄─┘
```

---

## Convenções

| Aspecto | Padrão |
|---------|--------|
| PKs | UUID com `gen_random_uuid()` |
| Timestamps | `TIMESTAMPTZ` com default `NOW()` |
| Soft delete | campo `ativo BOOLEAN` nas entidades principais |
| Auditoria | `data_cadastro` + `ultima_alteracao` em todas as tabelas |
| Status | `VARCHAR` com valores em SCREAMING_SNAKE_CASE |
| Nomenclatura | `snake_case`, sem prefixo de tabela nas colunas |
| Search path | `portal_b2b, public` — prefixo `portal_b2b.` desnecessário nas queries |
| Decimais | `DECIMAL(18,4)` para valores monetários e quantidades |
| Prazo frete | `INTEGER` (dias úteis) |

---

## Diferenças em relação ao script original

| Item | Script original (`b2b`) | Versão final (`portal_b2b`) |
|------|------------------------|------------------------------|
| Schema | `b2b` | `portal_b2b` |
| `demanda.status` | ausente | adicionado — RN-DEM-05 |
| `solicitacao_frete.status` | ausente | adicionado |
| `solicitacao_frete.data_criacao` | ausente | adicionado |
| `pedido.data_pedido` | ausente | adicionado |
| `usuario.data_cadastro` | ausente | adicionado |
| `cotacao_frete.prazo` | `VARCHAR(100)` | `INTEGER` (dias úteis) |
| Ownership | não definido | `db_portal_b2b` em todos os objetos |
| Grants explícitos | não definidos | `svc_portal_b2b` com DML |
| CHECKs | ausentes | adicionados em valores e quantidades |

---

## Ordem de Criação (migrations)

```
1.  perfil
2.  empresa
3.  empresa_perfil
4.  usuario
5.  endereco
6.  produto
7.  fornecimento
8.  demanda
9.  processo_negociacao
10. lance
11. pedido                    ← sem frete_selecionado_id ainda
12. item_pedido
13. solicitacao_frete
14. cotacao_frete
15. frete_selecionado
16. ALTER TABLE pedido        ← adiciona FK frete_selecionado_id (fecha referência circular)
```
