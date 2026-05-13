ALTER TABLE portal_b2b.demanda
    ADD COLUMN IF NOT EXISTS is_recorrente BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS observacoes   TEXT NULL;
-- ============================================================
-- Migration: Alinhamento final tabela demanda
-- ============================================================

-- Renomear PK para id_demanda
ALTER TABLE portal_b2b.demanda
    RENAME COLUMN id TO id_demanda;

-- Adicionar colunas faltantes
ALTER TABLE portal_b2b.demanda
    ADD COLUMN IF NOT EXISTS data_proxima_geracao DATE NULL,
    ADD COLUMN IF NOT EXISTS ultima_alteracao     TIMESTAMPTZ NULL;
