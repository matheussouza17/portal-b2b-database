-- ============================================================
-- Migration: Módulo Compradores — Integração Logística e Negociação
-- Schema: portal_b2b
-- Owner: db_portal_b2b
-- ============================================================

-- 1. Adiciona campos de integração logística e fechamento de negociação
ALTER TABLE portal_b2b.demanda
    ADD COLUMN IF NOT EXISTS tipo_transporte      VARCHAR(50) NULL DEFAULT 'RODOVIARIO',
    ADD COLUMN IF NOT EXISTS peso_carga            DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS cep_origem            VARCHAR(9) NULL,
    ADD COLUMN IF NOT EXISTS cep_destino           VARCHAR(9) NULL,
    ADD COLUMN IF NOT EXISTS id_fornecedor         UUID NULL,
    ADD COLUMN IF NOT EXISTS preco_final           DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS valor_total           DECIMAL(12,2) NULL,
    -- Campos adicionados para o fluxo de contratação do frete:
    ADD COLUMN IF NOT EXISTS id_frete_selecionado UUID NULL,
    ADD COLUMN IF NOT EXISTS valor_frete           DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS status_frete          VARCHAR(30) NULL DEFAULT 'PENDENTE';

-- 2. Adiciona constraint de Foreign Key para o fornecedor
ALTER TABLE portal_b2b.demanda
    DROP CONSTRAINT IF EXISTS fk_demanda_fornecedor;

ALTER TABLE portal_b2b.demanda
    ADD CONSTRAINT fk_demanda_fornecedor
        FOREIGN KEY (id_fornecedor)
        REFERENCES portal_b2b.empresa(id);

-- 3. Adiciona constraint de Foreign Key para o frete selecionado (Logística)
ALTER TABLE portal_b2b.demanda
    DROP CONSTRAINT IF EXISTS fk_demanda_frete;

ALTER TABLE portal_b2b.demanda
    ADD CONSTRAINT fk_demanda_frete
        FOREIGN KEY (id_frete_selecionado)
        REFERENCES portal_b2b.frete_selecionado(id);
