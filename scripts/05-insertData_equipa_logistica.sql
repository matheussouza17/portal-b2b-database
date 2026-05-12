-- 1. Inserir Perfis (Caso não existam)
INSERT INTO portal_b2b.perfil (nome) 
VALUES ('TRANSPORTADORA'), ('COMPRADOR'), ('FORNECEDOR')
ON CONFLICT (nome) DO NOTHING; 

-- 2. Inserir Tipos de Transporte (Crucial para a demo deles)
INSERT INTO portal_b2b.produtos_transporte (nome, descricao, ativo) VALUES
('Rodoviário', 'Transporte terrestre via caminhões', TRUE),
('Marítimo', 'Transporte via containers e navios', TRUE),
('Aéreo', 'Transporte de carga expressa via avião', TRUE)
ON CONFLICT (LOWER(nome)) DO NOTHING; 

-- 3. Criar Empresas de Teste (Bloco anônimo para pegar os IDs automáticos)
DO $$
DECLARE
    v_perfil_comprador UUID;
    v_perfil_transp UUID;
    v_empresa_comp UUID;
    v_empresa_transp UUID;
BEGIN
    SELECT id INTO v_perfil_comprador FROM portal_b2b.perfil WHERE nome = 'COMPRADOR'; [cite: 152]
    SELECT id INTO v_perfil_transp FROM portal_b2b.perfil WHERE nome = 'TRANSPORTADORA'; [cite: 153]

    -- Empresa Compradora
    INSERT INTO portal_b2b.empresa (razao_social, cnpj, email, status)
    VALUES ('Comprador Teste Logística', '00000000000191', 'compras@teste.com', 'ATIVO')
    ON CONFLICT (cnpj) DO UPDATE SET status = 'ATIVO' RETURNING id INTO v_empresa_comp; [cite: 155, 156, 157, 158]

    INSERT INTO portal_b2b.empresa_perfil (empresa_id, perfil_id) 
    VALUES (v_empresa_comp, v_perfil_comprador) ON CONFLICT DO NOTHING; [cite: 159, 160]

    -- Empresa Transportadora (Obrigatória para o microsserviço de logística)
    INSERT INTO portal_b2b.empresa (razao_social, cnpj, email, status)
    VALUES ('Transportadora Expressa B2B', '99999999000188', 'logistica@expressa.com', 'ATIVO')
    ON CONFLICT (cnpj) DO UPDATE SET status = 'ATIVO' RETURNING id INTO v_empresa_transp; [cite: 162, 163, 164, 165]

    INSERT INTO portal_b2b.empresa_perfil (empresa_id, perfil_id) 
    VALUES (v_empresa_transp, v_perfil_transp) ON CONFLICT DO NOTHING; [cite: 166, 167]
END $$;
