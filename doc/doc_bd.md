# Modelo ER — Portal B2B

## Visão Geral

O banco de dados utiliza o schema `portal_b2b` no PostgreSQL.

**Roles:**

| Role | Tipo | Permissões |
|------|------|------------|
| `db_portal_b2b` | Admin/DDL | Owner do schema, DDL, DML |
| `svc_portal_b2b` | Aplicação | SELECT, INSERT, UPDATE, DELETE (sem CREATE) |

> **Nota:** `svc_portal_b2b` não pode criar ou alterar objetos. Toda migração DDL deve ser executada como `db_portal_b2b`.

---

## Objetos Existentes

Criados em migrations anteriores:

| Objeto | Tipo |
|--------|------|
| `produtos_transporte` | Tabela |
| `produtos_categoria` | Tabela (auto-referenciada) |
| `produtos_unidade_medida` | Tabela |
| `produtos_produto` | Tabela |
| `fn_produtos_atualizar_ultima_alteracao()` | Trigger Function |
| `health_check` | Tabela |

> Todos os objetos acima têm owner `db_portal_b2b`.

---

## Entidades

### 1. empresa

Representa qualquer organização cadastrada. CNPJ único por empresa.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK, default `gen_random_uuid()` |
| `razao_social` | VARCHAR(200) | NOT NULL |
| `nome_fantasia` | VARCHAR(200) | NULL |
| `cnpj` | VARCHAR(14) | NOT NULL, UNIQUE |
| `email` | VARCHAR(150) | NOT NULL |
| `telefone` | VARCHAR(20) | NULL |
| `status` | VARCHAR(30) | NOT NULL, default `'ativo'` |
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
| `status` | VARCHAR(30) | NOT NULL, default `'ativo'` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 2. perfil

Papéis disponíveis no sistema. Valores fixos.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `nome` | VARCHAR(50) | NOT NULL, UNIQUE |

**Valores esperados:** `FORNECEDOR`, `COMPRADOR`, `TRANSPORTADORA`

---

### 3. empresa_perfil

Associação N:N entre empresa e perfil.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `empresa_id` | UUID | PK, FK → `empresa(id)` |
| `perfil_id` | UUID | PK, FK → `perfil(id)` |

---

### 4. endereco

Endereços vinculados a empresas.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_id` | UUID | FK → `empresa(id)` |
| `cidade` | VARCHAR(100) | NOT NULL |
| `estado` | CHAR(2) | NOT NULL |
| `cep` | VARCHAR(8) | NOT NULL |
| `latitude` | NUMERIC(9,6) | NULL |
| `longitude` | NUMERIC(9,6) | NULL |

---

### 5. produto *(integração com módulo existente)*

Catálogo genérico de produtos. **Sem preço e sem quantidade** — esses dados ficam em `fornecimento`.

Mapeado para as tabelas existentes:

| Campo lógico | Tabela física | Coluna |
|---|---|---|
| `id_produto` | `produtos_produto` | `id` |
| `nome` | `produtos_produto` | `nome` |
| `categoria` | `produtos_categoria` | `nome` |
| `unidade_medida` | `produtos_unidade_medida` | `sigla` |
| `tipo_transporte` | `produtos_transporte` | `nome` |

> Não criar tabela `produto` separada. Referenciar `produtos_produto` diretamente nas FKs.

---

### 6. fornecimento

Oferta de um fornecedor para um produto específico.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_fornecedor_id` | UUID | FK → `empresa(id)` |
| `produto_id` | UUID | FK → `produtos_produto(id)` |
| `preco_unitario` | NUMERIC(15,4) | NOT NULL, > 0 |
| `quantidade_disponivel` | NUMERIC(15,4) | NOT NULL, >= 0 |
| `endereco_origem_id` | UUID | FK → `endereco(id)` |
| `ativo` | BOOLEAN | NOT NULL, default `TRUE` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |
| `ultima_alteracao` | TIMESTAMPTZ | NULL |

---

### 7. demanda

Interesse de compra de um comprador.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `empresa_comprador_id` | UUID | FK → `empresa(id)` |
| `produto_id` | UUID | FK → `produtos_produto(id)` |
| `quantidade_desejada` | NUMERIC(15,4) | NOT NULL, > 0 |
| `endereco_destino_id` | UUID | FK → `endereco(id)` |
| `is_recorrente` | BOOLEAN | NOT NULL, default `FALSE` |
| `data_proxima_geracao` | DATE | NULL |
| `status` | VARCHAR(30) | NOT NULL, default `'aberta'` |
| `data_cadastro` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 8. processo_negociacao

Gerencia a negociação de compra/venda.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `produto_id` | UUID | FK → `produtos_produto(id)` |
| `modo` | VARCHAR(20) | NOT NULL — `direto`, `leilao_direto`, `leilao_reverso` |
| `status` | VARCHAR(30) | NOT NULL |
| `data_inicio` | TIMESTAMPTZ | NOT NULL |
| `data_fim` | TIMESTAMPTZ | NULL |
| `valor_reserva` | NUMERIC(15,4) | NULL |

---

### 9. lance

Propostas feitas durante um processo de negociação.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `processo_id` | UUID | FK → `processo_negociacao(id)` |
| `empresa_id` | UUID | FK → `empresa(id)` |
| `valor_unitario` | NUMERIC(15,4) | NOT NULL, > 0 |
| `quantidade` | NUMERIC(15,4) | NOT NULL, > 0 |
| `data_lance` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 10. pedido

Formaliza a compra após negociação concluída.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `processo_id` | UUID | FK → `processo_negociacao(id)` |
| `empresa_comprador_id` | UUID | FK → `empresa(id)` |
| `empresa_fornecedor_id` | UUID | FK → `empresa(id)` |
| `fornecimento_id` | UUID | FK → `fornecimento(id)` |
| `frete_selecionado_id` | UUID | FK → `frete_selecionado(id)`, NULL inicial |
| `valor_comissao` | NUMERIC(15,4) | NULL |
| `valor_total` | NUMERIC(15,4) | NOT NULL |
| `status` | VARCHAR(30) | NOT NULL |
| `data_pedido` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

> `frete_selecionado_id` é NULL no momento da criação do pedido e preenchido após seleção do frete.

---

### 11. item_pedido

Itens que compõem o pedido.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)` |
| `produto_id` | UUID | FK → `produtos_produto(id)` |
| `fornecimento_id` | UUID | FK → `fornecimento(id)` |
| `quantidade` | NUMERIC(15,4) | NOT NULL, > 0 |
| `valor_unitario` | NUMERIC(15,4) | NOT NULL, > 0 |

---

### 12. solicitacao_frete

Solicitação de frete gerada a partir de um pedido.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)` |
| `tipo_transporte` | VARCHAR(100) | NOT NULL |
| `status` | VARCHAR(30) | NOT NULL, default `'aguardando'` |
| `data_criacao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 13. cotacao_frete

Propostas de frete enviadas por transportadoras.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `solicitacao_id` | UUID | FK → `solicitacao_frete(id)` |
| `transportadora_id` | UUID | FK → `empresa(id)` |
| `valor` | NUMERIC(15,4) | NOT NULL, > 0 |
| `prazo` | INTEGER | NOT NULL — dias úteis |
| `data_cotacao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

### 14. frete_selecionado

Frete escolhido para o pedido.

| Coluna | Tipo | Restrições |
|--------|------|------------|
| `id` | UUID | PK |
| `pedido_id` | UUID | FK → `pedido(id)`, UNIQUE |
| `cotacao_id` | UUID | FK → `cotacao_frete(id)` |
| `data_selecao` | TIMESTAMPTZ | NOT NULL, default `NOW()` |

---

## Relacionamentos

```
empresa ─────────────── empresa_perfil ─────── perfil
empresa ─────────────── endereco
empresa ─────────────── usuario
empresa ─────────────── fornecimento ──────── produtos_produto
empresa ─────────────── demanda ────────────── produtos_produto
empresa ─────────────── lance ──────────────── processo_negociacao
processo_negociacao ─── pedido
pedido ──────────────── item_pedido
pedido ──────────────── solicitacao_frete ──── cotacao_frete
pedido ──────────────── frete_selecionado ───┘
```

---

## Convenções

- **PKs:** UUID (`gen_random_uuid()`) em todas as tabelas
- **Timestamps:** `TIMESTAMPTZ` com default `NOW()`
- **Soft delete:** campo `ativo BOOLEAN` nas entidades principais
- **Auditoria:** `data_cadastro`, `usuario_cadastro`, `ultima_alteracao`, `usuario_alteracao` onde aplicável
- **Trigger de auditoria:** `fn_produtos_atualizar_ultima_alteracao()` — padrão a replicar nas novas tabelas
- **Nomenclatura:** `snake_case`, sem prefixo de tabela nas colunas
- **Search path:** `portal_b2b, public` — não é necessário prefixar `portal_b2b.` nas queries

---

## Dependências de Criação (ordem)

1. `empresa`
2. `perfil`
3. `usuario`
4. `empresa_perfil`
5. `endereco`
6. `fornecimento`
7. `demanda`
8. `processo_negociacao`
9. `lance`
10. `pedido` *(sem FK frete_selecionado_id ainda)*
11. `item_pedido`
12. `solicitacao_frete`
13. `cotacao_frete`
14. `frete_selecionado`
15. `ALTER TABLE pedido ADD COLUMN frete_selecionado_id` *(fecha referência circular)*
