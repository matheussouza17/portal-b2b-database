-- Adds the id_fornecimento column to the demanda table in portal_b2b schema
ALTER TABLE portal_b2b.demanda ADD COLUMN id_fornecimento VARCHAR;
ALTER TABLE portal_b2b.demanda ADD COLUMN id_solicitacao_frete VARCHAR;
