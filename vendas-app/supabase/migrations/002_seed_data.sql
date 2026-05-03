-- ============================================================
-- SEED DATA — Dados de teste realistas
-- ============================================================

-- Configurações da vendedora
INSERT INTO settings (chave_pix, nome_vendedora) VALUES
  ('71999998888', 'Ana Barbosa');

-- ============================================================
-- PRODUTOS
-- ============================================================
INSERT INTO products (id, nome, categoria, preco_sugerido, tamanho, cor, marca, referencia) VALUES
  ('11111111-0001-0001-0001-000000000001', 'Blusa Floral Manga Longa',       'roupa_feminina',  79.90,  'M',      'Rosa',        'Renner',        'BL-001'),
  ('11111111-0001-0001-0001-000000000002', 'Calça Jeans Skinny',             'roupa_feminina',  129.90, '38',     'Azul',        'C&A',           'CJ-002'),
  ('11111111-0001-0001-0001-000000000003', 'Vestido Midi Estampado',         'roupa_feminina',  189.90, 'G',      'Verde',       'Marisa',        'VM-003'),
  ('11111111-0001-0001-0001-000000000004', 'Conjunto Cama Queen 200 Fios',   'cama_mesa_banho', 249.90, 'Queen',  'Branco',      'Santista',      'CM-004'),
  ('11111111-0001-0001-0001-000000000005', 'Sandália Salto Fino',            'calcados',         99.90, '37',     'Preto',       'Piccadilly',    'SS-005'),
  ('11111111-0001-0001-0001-000000000006', 'Tênis Casual Feminino',          'calcados',        149.90, '38',     'Branco',      'Moleca',        'TC-006'),
  ('11111111-0001-0001-0001-000000000007', 'Bolsa Tiracolo Couro Sintético', 'bolsa_acessorio',  89.90, 'Único',  'Caramelo',    'Di Valentini',  'BT-007'),
  ('11111111-0001-0001-0001-000000000008', 'Camiseta Polo Masculina',        'roupa_masculina',  69.90, 'G',      'Azul Marinho','Hering',        'CP-008');

-- ============================================================
-- CLIENTES (10 clientes com DDDs da Bahia)
-- ============================================================
INSERT INTO customers (id, nome, telefone, cpf, endereco, observacoes) VALUES
  ('22222222-0001-0001-0001-000000000001', 'Maria Silva',       '71991234567', '12345678901', 'Rua das Flores, 123, Brotas',               'Prefere parcelar em 5x, paga depois do dia 10'),
  ('22222222-0001-0001-0001-000000000002', 'Joana Santos',      '71998765432', '23456789012', 'Av. Paralela, 456, Valéria',                 'Paga sempre em dia'),
  ('22222222-0001-0001-0001-000000000003', 'Fernanda Oliveira', '73987654321', '34567890123', 'Rua do Mercado, 78, Feira de Santana',       'Gosta de roupas tamanho G'),
  ('22222222-0001-0001-0001-000000000004', 'Carla Mendes',      '71992345678', '45678901234', 'Travessa da Paz, 22, Liberdade',             NULL),
  ('22222222-0001-0001-0001-000000000005', 'Luciana Pereira',   '74993456789', '56789012345', 'Rua Nova, 88, Juazeiro',                    'Só pode pagar após dia 15'),
  ('22222222-0001-0001-0001-000000000006', 'Patrícia Costa',    '71994567890', '67890123456', 'Estrada de Ipitanga, 321, Lauro de Freitas', NULL),
  ('22222222-0001-0001-0001-000000000007', 'Renata Almeida',    '75995678901', '78901234567', 'Av. Central, 10, Feira de Santana',          'Compra muito cama/banho'),
  ('22222222-0001-0001-0001-000000000008', 'Simone Rodrigues',  '77996789012', '89012345678', 'Rua da Saudade, 55, Vitória da Conquista',   NULL),
  ('22222222-0001-0001-0001-000000000009', 'Tatiane Lima',      '71997890123', '90123456789', 'Rua Boa Vista, 200, Cajazeiras',             'Prefere parcelar em 3x'),
  ('22222222-0001-0001-0001-000000000010', 'Vanessa Ferreira',  '71998901234', '01234567890', 'Condomínio Solar, Bl 3 Ap 102, Pituba',     NULL);

-- ============================================================
-- VENDAS E PARCELAS
-- ============================================================

-- --------------------------------------------------
-- MARIA SILVA — Compra 1: out/2025  R$500, 5x
-- Parcela 1 PAGA em mar/2026 | Parcelas 2-5 ATRASADAS
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000001', '22222222-0001-0001-0001-000000000001',
   '2025-10-12', 'parcelado', 500.00, 0.00, 500.00, 5, '2025-11-12', 'atrasado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000001', '11111111-0001-0001-0001-000000000001', NULL,                  NULL,              2, 79.90),
  ('33333333-0001-0001-0001-000000000001', '11111111-0001-0001-0001-000000000003', NULL,                  NULL,              1, 189.90),
  ('33333333-0001-0001-0001-000000000001', NULL,                                   'Short jeans feminino','roupa_feminina',  1, 150.30);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, data_pagamento, status) VALUES
  ('44444444-0001-0001-0001-000000000001', '33333333-0001-0001-0001-000000000001', 1, 5, 100.00, '2025-11-12', '2026-03-05', 'pago'),
  ('44444444-0001-0001-0001-000000000002', '33333333-0001-0001-0001-000000000001', 2, 5, 100.00, '2025-12-12', NULL,         'atrasado'),
  ('44444444-0001-0001-0001-000000000003', '33333333-0001-0001-0001-000000000001', 3, 5, 100.00, '2026-01-12', NULL,         'atrasado'),
  ('44444444-0001-0001-0001-000000000004', '33333333-0001-0001-0001-000000000001', 4, 5, 100.00, '2026-02-12', NULL,         'atrasado'),
  ('44444444-0001-0001-0001-000000000005', '33333333-0001-0001-0001-000000000001', 5, 5, 100.00, '2026-03-12', NULL,         'atrasado');

INSERT INTO payments (installment_id, valor_pago, data_pagamento) VALUES
  ('44444444-0001-0001-0001-000000000001', 100.00, '2026-03-05');

-- --------------------------------------------------
-- MARIA SILVA — Compra 2: fev/2026  R$200, 2x — ATRASADAS
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000002', '22222222-0001-0001-0001-000000000001',
   '2026-02-01', 'parcelado', 200.00, 0.00, 200.00, 2, '2026-03-01', 'atrasado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000002', '11111111-0001-0001-0001-000000000007', NULL,            NULL,              1, 89.90),
  ('33333333-0001-0001-0001-000000000002', NULL,                                   'Lenço estampado','bolsa_acessorio', 1, 110.10);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000006', '33333333-0001-0001-0001-000000000002', 1, 2, 100.00, '2026-03-01', 'atrasado'),
  ('44444444-0001-0001-0001-000000000007', '33333333-0001-0001-0001-000000000002', 2, 2, 100.00, '2026-04-01', 'atrasado');

-- --------------------------------------------------
-- JOANA SANTOS — quitada: jan/2026  R$260, 2x
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000003', '22222222-0001-0001-0001-000000000002',
   '2026-01-10', 'parcelado', 260.00, 0.00, 260.00, 2, '2026-02-10', 'quitado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000003', '11111111-0001-0001-0001-000000000001', NULL,                       NULL,   1, 79.90),
  ('33333333-0001-0001-0001-000000000003', '11111111-0001-0001-0001-000000000005', NULL,                       NULL,   1, 99.90),
  ('33333333-0001-0001-0001-000000000003', NULL,                                   'Meias femininas kit 3 pares','outro', 1, 80.20);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, data_pagamento, status) VALUES
  ('44444444-0001-0001-0001-000000000008', '33333333-0001-0001-0001-000000000003', 1, 2, 130.00, '2026-02-10', '2026-02-10', 'pago'),
  ('44444444-0001-0001-0001-000000000009', '33333333-0001-0001-0001-000000000003', 2, 2, 130.00, '2026-03-10', '2026-03-10', 'pago');

INSERT INTO payments (installment_id, valor_pago, data_pagamento) VALUES
  ('44444444-0001-0001-0001-000000000008', 130.00, '2026-02-10'),
  ('44444444-0001-0001-0001-000000000009', 130.00, '2026-03-10');

-- --------------------------------------------------
-- FERNANDA OLIVEIRA — em dia: abr/2026  R$380, 3x
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000004', '22222222-0001-0001-0001-000000000003',
   '2026-04-05', 'parcelado', 380.00, 0.00, 380.00, 3, '2026-05-05', 'em_dia');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000004', '11111111-0001-0001-0001-000000000003', NULL,                   NULL,              1, 189.90),
  ('33333333-0001-0001-0001-000000000004', '11111111-0001-0001-0001-000000000002', NULL,                   NULL,              1, 129.90),
  ('33333333-0001-0001-0001-000000000004', NULL,                                   'Cinto de couro feminino','bolsa_acessorio', 1, 60.20);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000010', '33333333-0001-0001-0001-000000000004', 1, 3, 126.67, '2026-05-05', 'pendente'),
  ('44444444-0001-0001-0001-000000000011', '33333333-0001-0001-0001-000000000004', 2, 3, 126.67, '2026-06-05', 'pendente'),
  ('44444444-0001-0001-0001-000000000012', '33333333-0001-0001-0001-000000000004', 3, 3, 126.66, '2026-07-05', 'pendente');

-- --------------------------------------------------
-- CARLA MENDES — PIX quitado na hora: abr/2026
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000005', '22222222-0001-0001-0001-000000000004',
   '2026-04-20', 'pix', 149.90, 149.90, 0.00, 1, '2026-04-20', 'quitado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000005', '11111111-0001-0001-0001-000000000006', NULL, NULL, 1, 149.90);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, data_pagamento, status) VALUES
  ('44444444-0001-0001-0001-000000000013', '33333333-0001-0001-0001-000000000005', 1, 1, 0.00, '2026-04-20', '2026-04-20', 'pago');

INSERT INTO payments (installment_id, valor_pago, data_pagamento) VALUES
  ('44444444-0001-0001-0001-000000000013', 0.00, '2026-04-20');

-- --------------------------------------------------
-- LUCIANA PEREIRA — atrasada: mar/2026  R$350, 4x
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000006', '22222222-0001-0001-0001-000000000005',
   '2026-03-01', 'parcelado', 350.00, 50.00, 300.00, 4, '2026-04-01', 'atrasado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000006', '11111111-0001-0001-0001-000000000004', NULL,                     NULL,              1, 249.90),
  ('33333333-0001-0001-0001-000000000006', NULL,                                   'Jogo de toalhas de banho','cama_mesa_banho', 2, 50.05);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000014', '33333333-0001-0001-0001-000000000006', 1, 4, 75.00, '2026-04-01', 'atrasado'),
  ('44444444-0001-0001-0001-000000000015', '33333333-0001-0001-0001-000000000006', 2, 4, 75.00, '2026-05-01', 'atrasado'),
  ('44444444-0001-0001-0001-000000000016', '33333333-0001-0001-0001-000000000006', 3, 4, 75.00, '2026-06-01', 'pendente'),
  ('44444444-0001-0001-0001-000000000017', '33333333-0001-0001-0001-000000000006', 4, 4, 75.00, '2026-07-01', 'pendente');

-- --------------------------------------------------
-- PATRÍCIA COSTA — parcela vencendo HOJE (2026-05-03)
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000007', '22222222-0001-0001-0001-000000000006',
   '2026-04-03', 'parcelado', 179.80, 0.00, 179.80, 2, '2026-05-03', 'em_dia');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000007', '11111111-0001-0001-0001-000000000001', NULL,          NULL,              1, 79.90),
  ('33333333-0001-0001-0001-000000000007', '11111111-0001-0001-0001-000000000007', NULL,          NULL,              1, 89.90),
  ('33333333-0001-0001-0001-000000000007', NULL,                                   'Laço de cabelo','bolsa_acessorio', 1, 10.00);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000018', '33333333-0001-0001-0001-000000000007', 1, 2, 89.90, '2026-05-03', 'pendente'),
  ('44444444-0001-0001-0001-000000000019', '33333333-0001-0001-0001-000000000007', 2, 2, 89.90, '2026-06-03', 'pendente');

-- --------------------------------------------------
-- RENATA ALMEIDA — em dia: mai/2026  R$249.90, 3x
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000008', '22222222-0001-0001-0001-000000000007',
   '2026-05-01', 'parcelado', 249.90, 0.00, 249.90, 3, '2026-06-01', 'em_dia');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000008', '11111111-0001-0001-0001-000000000004', NULL, NULL, 1, 249.90);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000020', '33333333-0001-0001-0001-000000000008', 1, 3, 83.30, '2026-06-01', 'pendente'),
  ('44444444-0001-0001-0001-000000000021', '33333333-0001-0001-0001-000000000008', 2, 3, 83.30, '2026-07-01', 'pendente'),
  ('44444444-0001-0001-0001-000000000022', '33333333-0001-0001-0001-000000000008', 3, 3, 83.30, '2026-08-01', 'pendente');

-- --------------------------------------------------
-- SIMONE RODRIGUES — parcela vencendo HOJE (2026-05-03)
-- --------------------------------------------------
INSERT INTO sales (id, customer_id, data_venda, forma_pagamento, total_bruto, entrada_valor, total_parcelado, num_parcelas, data_primeiro_vencimento, status) VALUES
  ('33333333-0001-0001-0001-000000000009', '22222222-0001-0001-0001-000000000008',
   '2026-02-15', 'parcelado', 219.80, 0.00, 219.80, 3, '2026-03-15', 'atrasado');

INSERT INTO sale_items (sale_id, product_id, descricao_livre, categoria_livre, quantidade, preco_unitario) VALUES
  ('33333333-0001-0001-0001-000000000009', '11111111-0001-0001-0001-000000000005', NULL,                    NULL,              1, 99.90),
  ('33333333-0001-0001-0001-000000000009', '11111111-0001-0001-0001-000000000008', NULL,                    NULL,              1, 69.90),
  ('33333333-0001-0001-0001-000000000009', NULL,                                   'Bermuda jeans masculina','roupa_masculina', 1, 50.00);

INSERT INTO installments (id, sale_id, numero_parcela, total_parcelas, valor, data_vencimento, status) VALUES
  ('44444444-0001-0001-0001-000000000023', '33333333-0001-0001-0001-000000000009', 1, 3, 73.27, '2026-03-15', 'atrasado'),
  ('44444444-0001-0001-0001-000000000024', '33333333-0001-0001-0001-000000000009', 2, 3, 73.27, '2026-04-15', 'atrasado'),
  ('44444444-0001-0001-0001-000000000025', '33333333-0001-0001-0001-000000000009', 3, 3, 73.26, '2026-05-03', 'pendente');
