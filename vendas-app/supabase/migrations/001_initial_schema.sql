-- ============================================================
-- CUSTOMERS — dados das clientes
-- ============================================================
CREATE TABLE customers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome          TEXT NOT NULL,
  telefone      TEXT NOT NULL,        -- formato: 71999998888 (somente números)
  cpf           TEXT,                 -- opcional, somente números
  endereco      TEXT,
  foto_url      TEXT,
  observacoes   TEXT,
  ativo         BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PRODUCTS — catálogo de produtos
-- ============================================================
CREATE TYPE product_category AS ENUM (
  'roupa_feminina',
  'roupa_masculina',
  'roupa_infantil',
  'cama_mesa_banho',
  'calcados',
  'bolsa_acessorio',
  'outro'
);

CREATE TABLE products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome             TEXT NOT NULL,
  categoria        product_category NOT NULL,
  preco_sugerido   NUMERIC(10,2),
  descricao        TEXT,
  tamanho          TEXT,             -- ex: P, M, G, GG, 38, 39...
  cor              TEXT,
  marca            TEXT,
  referencia       TEXT,             -- código interno ou referência do fornecedor
  ativo            BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SALES — cada compra é uma nota independente
-- Uma mesma cliente pode ter N sales abertas simultaneamente
-- ============================================================
CREATE TYPE sale_status AS ENUM ('em_dia', 'atrasado', 'quitado');
CREATE TYPE forma_pagamento AS ENUM ('pix', 'parcelado');

CREATE TABLE sales (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id       UUID NOT NULL REFERENCES customers(id),
  data_venda        DATE NOT NULL DEFAULT CURRENT_DATE,
  forma_pagamento   forma_pagamento NOT NULL,       -- 'pix' ou 'parcelado'
  total_bruto       NUMERIC(10,2) NOT NULL,          -- soma dos itens
  entrada_valor     NUMERIC(10,2) DEFAULT 0,         -- valor pago na hora (pode ser 0)
  total_parcelado   NUMERIC(10,2) NOT NULL,           -- total_bruto - entrada_valor
  num_parcelas      INTEGER NOT NULL DEFAULT 1,       -- 1 = à vista/pix, 2+ = parcelado
  data_primeiro_vencimento DATE NOT NULL,
  observacoes       TEXT,
  status            sale_status DEFAULT 'em_dia',
  whatsapp_confirmacao_enviado    BOOLEAN DEFAULT false,
  whatsapp_confirmacao_enviado_em TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SALE_ITEMS — produtos de cada venda
-- ============================================================
CREATE TABLE sale_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id           UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id        UUID REFERENCES products(id),   -- NULL para item avulso
  descricao_livre   TEXT,      -- preenchido quando product_id é NULL
  categoria_livre   TEXT,      -- categoria do item avulso (opcional)
  quantidade        INTEGER NOT NULL DEFAULT 1,
  preco_unitario    NUMERIC(10,2) NOT NULL,
  subtotal          NUMERIC(10,2) GENERATED ALWAYS AS (quantidade * preco_unitario) STORED,
  CONSTRAINT item_deve_ter_produto_ou_descricao
    CHECK (product_id IS NOT NULL OR descricao_livre IS NOT NULL)
);

-- ============================================================
-- INSTALLMENTS — parcelas de cada venda (independentes por venda)
-- ============================================================
CREATE TYPE installment_status AS ENUM ('pendente', 'pago', 'atrasado');

CREATE TABLE installments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id             UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  numero_parcela      INTEGER NOT NULL,          -- 1, 2, 3...
  total_parcelas      INTEGER NOT NULL,          -- total de parcelas da venda
  valor               NUMERIC(10,2) NOT NULL,
  data_vencimento     DATE NOT NULL,
  data_pagamento      DATE,                      -- NULL = não pago ainda
  status              installment_status DEFAULT 'pendente',
  whatsapp_enviado    BOOLEAN DEFAULT false,
  whatsapp_enviado_em TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT now(),
  UNIQUE(sale_id, numero_parcela)
);

-- ============================================================
-- PAYMENTS — histórico de pagamentos recebidos
-- ============================================================
CREATE TABLE payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installment_id  UUID NOT NULL REFERENCES installments(id),
  valor_pago      NUMERIC(10,2) NOT NULL,
  data_pagamento  DATE NOT NULL DEFAULT CURRENT_DATE,
  observacoes     TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SETTINGS — configurações da vendedora (linha única)
-- ============================================================
CREATE TABLE settings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chave_pix       TEXT,          -- chave PIX enviada no WhatsApp ao fechar venda PIX
  nome_vendedora  TEXT,          -- usado nas mensagens do WhatsApp
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER settings_updated_at
  BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE customers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE products     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments     ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_all" ON customers    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_all" ON products     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_all" ON sales        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_all" ON sale_items   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_all" ON installments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_all" ON payments     FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- ÍNDICES para performance
-- ============================================================
CREATE INDEX idx_sales_customer       ON sales(customer_id);
CREATE INDEX idx_sale_items_sale      ON sale_items(sale_id);
CREATE INDEX idx_installments_sale    ON installments(sale_id);
CREATE INDEX idx_installments_status  ON installments(status);
CREATE INDEX idx_installments_venc    ON installments(data_vencimento);
