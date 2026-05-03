# Prompt — App de Gestão de Vendas (Flutter + FastAPI + Supabase)

> Cole este prompt no Claude Code para iniciar o projeto.

---

## CONTEXTO DO PROJETO

Você é um engenheiro sênior especialista em Flutter, FastAPI e Supabase. Vou construir um app mobile completo de gestão de vendas para uma vendedora autônoma que vende roupas, cama/mesa/banho, sapatos e outros produtos. Hoje ela anota tudo no papel — o app vai digitalizar isso completamente.

**Arquitetura geral:**
- **Backend:** FastAPI (Python) — responsável por toda a lógica de negócio
- **Banco de dados:** Supabase (PostgreSQL) — usado apenas como banco e autenticação, sem Edge Functions
- **App:** Flutter — apenas chama as rotas HTTP do backend

**Regras do negócio mais importantes:**
- Uma cliente pode ter **múltiplas compras independentes**, cada uma com suas próprias parcelas
- Exemplo real: cliente fez compra em 12/10/2025 (R$ 500) e outra em 01/02/2026 (R$ 200). São duas notas separadas, com parcelas separadas
- Um pagamento de parcela da compra 1 não afeta as parcelas da compra 2
- O saldo devedor total da cliente é a soma de todas as parcelas pendentes de todas as compras
- Clientes **não têm acesso ao app** — o app é usado somente pela vendedora
- **Não há integração com gateway de pagamento.** O app apenas envia mensagens via WhatsApp:
  - **Venda à vista (PIX):** ao confirmar a venda, manda mensagem com a chave PIX da vendedora e o valor a pagar
  - **Venda parcelada:** ao confirmar a venda, manda mensagem de confirmação com resumo dos produtos, valor total e tabela de parcelas
  - **Cobrança de parcela:** quando chega o dia do vencimento, manda lembrete da parcela pendente

---

## BANCO DE DADOS — Schema Supabase

Crie o arquivo `supabase/migrations/001_initial_schema.sql` com o schema completo:

```sql
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
-- Suporta dois tipos de item:
--   1. produto cadastrado (product_id preenchido)
--   2. item avulso (product_id nulo, descricao_livre preenchida)
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
-- Apenas o usuário admin autenticado acessa tudo
-- ============================================================
ALTER TABLE customers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE products     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments     ENABLE ROW LEVEL SECURITY;

-- Policy: usuário autenticado tem acesso total
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
```

---

## ESTRUTURA DO MONOREPO

Todo o projeto fica em uma única pasta. O Claude Code consegue ver e editar tanto o backend quanto o app ao mesmo tempo.

```
vendas-app/
  backend/                           # BACKEND FASTAPI
    main.py                          # entry point — monta o app e registra os routers
    requirements.txt
    .env                             # variáveis de ambiente (não commitar)
    routers/
      auth.py                        # login / refresh de token (delega ao Supabase Auth)
      customers.py                   # CRUD de clientes
      products.py                    # CRUD de produtos
      sales.py                       # criar venda + gerar parcelas
      installments.py                # listar, marcar como pago, atualizar vencidas
      dashboard.py                   # métricas do dashboard em uma chamada
      settings.py                    # configurações da vendedora (chave PIX, nome)
    services/
      supabase_client.py             # cliente Supabase compartilhado
      installment_service.py         # lógica de geração e atualização de parcelas
    models/
      schemas.py                     # Pydantic models (request/response)
    scheduler.py                     # APScheduler — atualiza vencidas todo dia às 06h

  supabase/                          # APENAS BANCO DE DADOS
    config.toml
    migrations/
      001_initial_schema.sql
      002_seed_data.sql
    .env.local                       # variáveis locais (não commitar)

  app/                               # APP FLUTTER
    pubspec.yaml
    lib/
      ...
    android/
    ios/

  .gitignore
  README.md
```

---

## BACKEND — FastAPI

### Dependências (`backend/requirements.txt`)

```
fastapi==0.111.0
uvicorn[standard]==0.29.0
supabase==2.4.0
python-dotenv==1.0.1
pydantic==2.7.1
apscheduler==3.10.4
httpx==0.27.0
```

### Variáveis de ambiente (`backend/.env`)

```env
# Não commitar este arquivo
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key_local
SECRET_KEY=chave_secreta_para_verificar_token_jwt
```

### Entry point (`backend/main.py`)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, customers, products, sales, installments, dashboard, settings
from scheduler import start_scheduler

app = FastAPI(title="Vendas App API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(customers.router, prefix="/customers", tags=["customers"])
app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(sales.router, prefix="/sales", tags=["sales"])
app.include_router(installments.router, prefix="/installments", tags=["installments"])
app.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
app.include_router(settings.router, prefix="/settings", tags=["settings"])

@app.on_event("startup")
async def startup():
    start_scheduler()

@app.get("/health")
def health():
    return {"status": "ok"}
```

### Cliente Supabase (`backend/services/supabase_client.py`)

```python
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

supabase: Client = create_client(
    os.environ["SUPABASE_URL"],
    os.environ["SUPABASE_SERVICE_ROLE_KEY"],
)
```

### Autenticação (`backend/routers/auth.py`)

O backend **não** gerencia sessões — delega completamente ao Supabase Auth. O Flutter usa o SDK do Supabase para login e envia o JWT nas requisições ao backend. O backend apenas valida o token.

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from services.supabase_client import supabase

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Valida o JWT do Supabase. Lança 401 se inválido."""
    token = credentials.credentials
    try:
        user = supabase.auth.get_user(token)
        return user
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido")
```

> Todas as rotas protegidas recebem `user = Depends(get_current_user)` como parâmetro.

---

### Rotas — Clientes (`backend/routers/customers.py`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/customers` | Lista clientes (filtros: status, busca por nome/telefone) |
| POST | `/customers` | Cadastra nova cliente |
| GET | `/customers/{id}` | Detalhe da cliente com todas as compras |
| PUT | `/customers/{id}` | Atualiza dados da cliente |
| GET | `/customers/{id}/balance` | Saldo devedor total (soma de todas as parcelas em aberto) |

**Lógica do balance:**
Soma todas as parcelas com `status IN ('pendente', 'atrasado')` de todas as vendas da cliente, via join `installments → sales → customer_id`.

---

### Rotas — Produtos (`backend/routers/products.py`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/products` | Lista produtos (filtros: categoria, ativo, busca por nome/marca/referência) |
| POST | `/products` | Cadastra novo produto |
| PUT | `/products/{id}` | Atualiza produto |
| DELETE | `/products/{id}` | Inativa produto (soft delete — `ativo = false`) |

---

### Rotas — Vendas (`backend/routers/sales.py`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/sales` | Cria venda + itens + gera parcelas automaticamente |
| GET | `/sales/{id}` | Detalhe da venda com itens e parcelas |

**Lógica do POST `/sales`:**
1. Insere registro em `sales`
2. Insere todos os itens em `sale_items`
3. Chama `installment_service.generate_installments(sale_id)` para gerar as parcelas
4. Retorna a venda completa com parcelas

---

### Serviço de Parcelas (`backend/services/installment_service.py`)

```python
from datetime import date
from dateutil.relativedelta import relativedelta
from services.supabase_client import supabase

def generate_installments(sale_id: str):
    """Gera todas as parcelas de uma venda."""
    sale = supabase.table("sales").select("*").eq("id", sale_id).single().execute().data

    total = float(sale["total_parcelado"])
    n = sale["num_parcelas"]
    data_base = date.fromisoformat(sale["data_primeiro_vencimento"])

    valor_base = round(total / n, 2)
    ajuste = round(total - valor_base * n, 2)

    installments = []
    for i in range(n):
        valor = round(valor_base + (ajuste if i == n - 1 else 0), 2)
        data_venc = data_base + relativedelta(months=i)
        installments.append({
            "sale_id": sale_id,
            "numero_parcela": i + 1,
            "total_parcelas": n,
            "valor": valor,
            "data_vencimento": data_venc.isoformat(),
            "status": "pendente",
        })

    return supabase.table("installments").insert(installments).execute().data


def update_overdue():
    """Marca parcelas vencidas como atrasadas e atualiza status das vendas."""
    hoje = date.today().isoformat()

    # 1. Buscar parcelas que precisam ser marcadas como atrasadas
    result = (
        supabase.table("installments")
        .select("id, sale_id")
        .eq("status", "pendente")
        .lt("data_vencimento", hoje)
        .is_("data_pagamento", "null")
        .execute()
    )
    parcelas = result.data or []

    if not parcelas:
        return {"parcelas_atualizadas": 0, "vendas_atualizadas": 0}

    ids = [p["id"] for p in parcelas]
    sale_ids = list({p["sale_id"] for p in parcelas})

    # 2. Atualizar status para atrasado
    supabase.table("installments").update({"status": "atrasado"}).in_("id", ids).execute()

    # 3. Atualizar status de cada venda afetada
    for sale_id in sale_ids:
        todas = supabase.table("installments").select("status").eq("sale_id", sale_id).execute().data or []
        todas_pagas = all(p["status"] == "pago" for p in todas)
        alguma_atrasada = any(p["status"] == "atrasado" for p in todas)
        novo_status = "quitado" if todas_pagas else "atrasado" if alguma_atrasada else "em_dia"
        supabase.table("sales").update({"status": novo_status}).eq("id", sale_id).execute()

    return {"parcelas_atualizadas": len(ids), "vendas_atualizadas": len(sale_ids)}
```

---

### Rotas — Parcelas (`backend/routers/installments.py`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/installments` | Lista parcelas com filtros (status, data, busca por cliente) |
| POST | `/installments/{id}/pay` | Registra pagamento de uma parcela |
| POST | `/installments/update-overdue` | Atualiza manualmente parcelas vencidas (uso interno) |

**Lógica do POST `/installments/{id}/pay`:**
1. Verifica se a parcela existe e não está paga
2. Insere em `payments`
3. Atualiza `installments`: `status = 'pago'`, `data_pagamento`
4. Verifica se todas as parcelas da venda estão pagas → `sales.status = 'quitado'`
5. Retorna parcela atualizada + novo status da venda

---

### Rotas — Dashboard (`backend/routers/dashboard.py`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/dashboard/metrics` | Todas as métricas em uma chamada |
| GET | `/dashboard/today` | Parcelas de hoje + atrasadas para a seção "Cobranças do dia" |

**Métricas retornadas por `/dashboard/metrics`:**
```json
{
  "total_faturado_mes": 4500.00,
  "total_recebido_mes": 2300.00,
  "clientes_com_debito": 8,
  "parcelas_vencidas": 3,
  "parcelas_vencendo_hoje": 2,
  "total_em_aberto": 6800.00
}
```
Usa `asyncio.gather` ou queries paralelas para máxima performance.

---

### Rotas — Configurações (`backend/routers/settings.py`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/settings` | Retorna configurações da vendedora |
| PUT | `/settings` | Atualiza chave PIX e nome da vendedora |

---

### Agendamento diário (`backend/scheduler.py`)

```python
from apscheduler.schedulers.background import BackgroundScheduler
from services.installment_service import update_overdue

def start_scheduler():
    scheduler = BackgroundScheduler(timezone="America/Bahia")
    # Roda todo dia às 06:00 horário de Brasília
    scheduler.add_job(update_overdue, "cron", hour=6, minute=0)
    scheduler.start()
```

### Rodando o backend localmente

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# Documentação interativa disponível em: http://localhost:8000/docs
```

### Deploy do backend (Railway ou Render — plano gratuito)

```bash
# Railway
railway login
railway init
railway up

# Render: conectar repositório pelo painel e definir:
#   Build command: pip install -r requirements.txt
#   Start command: uvicorn main:app --host 0.0.0.0 --port $PORT
```

Defina as variáveis de ambiente (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SECRET_KEY`) no painel do Railway ou Render.

---

## ESTRUTURA DO APP FLUTTER

```
lib/
  main.dart
  app.dart
  core/
    api_client.dart              # cliente HTTP central (Dio ou http) com base URL e token
    router.dart
    theme.dart
    utils/
      whatsapp_helper.dart
      currency_formatter.dart
      date_formatter.dart
      mask_formatters.dart
  features/
    auth/
      login_screen.dart
    dashboard/
      dashboard_screen.dart
      widgets/
        metric_card.dart
        cobrancas_do_dia_card.dart
        ultimas_vendas_card.dart
    customers/
      customers_list_screen.dart
      customer_detail_screen.dart
      customer_form_screen.dart
      widgets/
        customer_card.dart
        customer_balance_card.dart
        customer_sales_list.dart
    sales/
      new_sale_screen.dart          # stepper em 3 etapas
      sale_detail_screen.dart
      widgets/
        step_selecionar_cliente.dart
        step_adicionar_itens.dart
        step_condicoes_pagamento.dart
        item_avulso_bottom_sheet.dart
        produto_search_bottom_sheet.dart
        parcelas_preview.dart
    installments/
      installments_screen.dart
      installment_detail_screen.dart
      widgets/
        installment_card.dart
    products/
      products_screen.dart
      product_form_screen.dart
      widgets/
        product_card.dart
    reports/
      reports_screen.dart
      widgets/
        report_metric_card.dart
        devedoras_list.dart
```

---

## CLIENTE HTTP DO FLUTTER (`lib/core/api_client.dart`)

O Flutter **não** usa o SDK do Supabase para acessar dados — usa apenas o SDK do Supabase para autenticação (obter o JWT). Todas as chamadas de dados vão para o backend FastAPI.

```dart
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ${response.statusCode}: ${response.body}');
  }
}
```

**Exemplos de chamadas no Flutter:**

```dart
// Buscar métricas do dashboard
final metrics = await ApiClient.get('/dashboard/metrics');

// Criar nova venda
final sale = await ApiClient.post('/sales', {
  'customer_id': customerId,
  'forma_pagamento': 'parcelado',
  'total_bruto': 500.0,
  'entrada_valor': 0.0,
  'total_parcelado': 500.0,
  'num_parcelas': 5,
  'data_primeiro_vencimento': '2026-06-01',
  'items': [...],
});

// Marcar parcela como paga
await ApiClient.post('/installments/$installmentId/pay', {
  'data_pagamento': '2026-05-03',
  'observacoes': 'Pago via PIX',
});

// Saldo devedor da cliente
final balance = await ApiClient.get('/customers/$customerId/balance');
```

---

## TELAS E FUNCIONALIDADES

### Login
- E-mail + senha via Supabase Auth (SDK Flutter)
- Salvar sessão — ao reabrir o app, mantém logado
- Visual simples com nome do negócio e logo placeholder

---

### Dashboard
Cards de métricas no topo (grid 2x2):
- 💰 Total faturado no mês
- 📥 Total recebido no mês
- ⚠️ Parcelas vencidas (inadimplência)
- 📅 Parcelas vencendo hoje

**Seção "Cobranças de hoje":**
- Lista de parcelas com `data_vencimento = hoje` + parcelas `atrasadas`
- Cada item: nome da cliente, valor, nº da parcela (ex: 2/6), dias de atraso se houver
- Botão "💬 WhatsApp" em cada item — abre WA com mensagem personalizada
- Ao enviar, chama `PUT /installments/{id}` marcando `whatsapp_enviado = true`

**Seção "Últimas vendas":**
- 5 vendas mais recentes com nome da cliente, data, valor e badge de status

---

### WhatsApp Helper

Crie `lib/core/utils/whatsapp_helper.dart` com a função `abrirWhatsApp`:

```dart
// Parâmetros: nome, telefone, numeroParcela, totalParcelas, valor, dataVencimento, diasAtraso
// Formata o telefone: remove tudo que não é dígito, adiciona "55" na frente
// Escolhe a mensagem com base nos diasAtraso:
//
//   diasAtraso == 0 (vence hoje):
//   "Olá [Nome]! 😊 Passando para lembrar que sua parcela [X/Y] de R$ [valor]
//    vence hoje. Qualquer dúvida me chame! 🙏"
//
//   diasAtraso entre 1 e 3:
//   "Olá [Nome]! 😊 Tudo bem? Vi aqui que sua parcela [X/Y] de R$ [valor]
//    venceu há [N] dia(s). Quando puder, me avisa! 💛"
//
//   diasAtraso > 3:
//   "Olá [Nome]! Passando para avisar que sua parcela [X/Y] de R$ [valor]
//    está em aberto desde [data]. Podemos combinar o pagamento? 😊"
//
// Ao confirmar VENDA PIX — mensagem enviada ao fechar a venda:
//   "Olá [Nome]! 😊 Obrigada pela compra de R$ [valor]!
//    Para finalizar, faça o pagamento via PIX para a chave: [chave_pix] 🙏"
//
// Ao confirmar VENDA PARCELADA — mensagem enviada ao fechar a venda:
//   "Olá [Nome]! 😊 Confirmando sua compra:
//    [lista de itens]
//    Total: R$ [valor_total]
//    Parcelado em [N]x de R$ [valor_parcela]
//    1ª parcela: [data]
//    Qualquer dúvida me chame! 💛"
//
// Abre com url_launcher: https://wa.me/55TELEFONE?text=MENSAGEM_URI_ENCODED
// Retorna bool — true se conseguiu abrir, false caso contrário
```

---

### Clientes — Lista
- Busca em tempo real por nome ou telefone
- Filtros (chips): Todos / Em dia / Com atraso / Sem compras
- Card de cada cliente: avatar com inicial, nome, telefone, saldo devedor total, badge de status
- FAB (+) para cadastrar nova cliente

### Clientes — Detalhe
- Avatar/foto, nome, telefone (toque para ligar), CPF, endereço, observações
- **Saldo devedor total** em destaque (soma de todas as compras em aberto) — via `GET /customers/{id}/balance`
- **Lista de compras** — cada compra exibe:
  - Data da compra
  - Total da nota
  - Parcelas: "3 de 6 pagas" com barra de progresso
  - Badge de status (em dia / atrasado / quitado)
  - Toque → abre detalhe da venda
- Botão "Nova venda" para essa cliente
- Botão "Cobrar no WhatsApp" (aparece se tiver parcelas em aberto)

### Clientes — Formulário de Cadastro / Edição
Campos obrigatórios:
- Nome completo
- Telefone — máscara `(99) 99999-9999`, armazena apenas dígitos

Campos opcionais:
- CPF — máscara `999.999.999-99`
- Endereço (rua, número, bairro — campo livre)
- Observações (ex: "prefere parcelar em 3x", "só pode pagar depois do dia 10")
- Foto — câmera ou galeria, upload para Supabase Storage

---

### Nova Venda — Stepper em 3 etapas

**Etapa 1 — Selecionar Cliente**
- Campo de busca com autocomplete (nome ou telefone) — chama `GET /customers?busca=...`
- Ao selecionar: mostra card resumido da cliente com saldo atual
- Botão "+ Cadastrar nova cliente" — abre formulário em modal, ao salvar já seleciona a nova cliente

**Etapa 2 — Adicionar Itens**

Esta etapa suporta **dois modos de inserção de item**, que podem ser usados juntos na mesma venda:

**Modo A — Buscar produto cadastrado:**
- Campo de busca abre bottom sheet com lista de produtos — chama `GET /products?busca=...`
- Busca por nome, categoria ou referência
- Filtro por categoria no topo do bottom sheet
- Ao selecionar: preenche automaticamente descrição e preço sugerido (editável)
- Permite ajustar quantidade

**Modo B — Item avulso (produto não cadastrado):**
- Botão "+ Adicionar item avulso"
- Bottom sheet com campos:
  - Descrição do produto (ex: "Blusa floral manga longa")
  - Categoria (dropdown com as mesmas categorias do catálogo)
  - Quantidade
  - Preço unitário
- Opção: "Salvar no catálogo para usar depois" (checkbox — chama `POST /products` se marcado)

**Lista de itens adicionados:**
- Cada item: descrição, quantidade × preço, subtotal
- Badge diferenciando produto do catálogo vs avulso
- Deslizar para remover
- Total da compra em tempo real no rodapé

**Etapa 3 — Condições de Pagamento**
- Forma de pagamento: PIX ou Parcelado
- Entrada (pode ser R$ 0,00) — deduzida automaticamente
- Número de parcelas: 1x até 24x (seletor numérico) — visível apenas se "Parcelado"
- Data do 1º vencimento (date picker)
- **Preview das parcelas geradas** — calculado localmente no Flutter antes de confirmar
- Observações
- Botão "Confirmar Venda"

Ao confirmar: chama `POST /sales` com todos os dados. O backend cria a venda, os itens e as parcelas.
Após confirmação: abre WhatsApp automaticamente com mensagem de confirmação (PIX ou parcelado).

---

### Detalhe da Venda
- Data da venda, cliente, status
- Lista de itens comprados (descrição, qtd, valor unitário, subtotal)
- Total bruto, entrada paga, total parcelado
- **Timeline de parcelas** — cada parcela mostra:
  - Número (ex: 2/6)
  - Data de vencimento
  - Valor
  - Status visual: ✅ pago (verde) | 🔵 pendente | ❌ atrasado (vermelho)
  - Data em que foi paga (se pago)
  - Botão "Marcar como pago" (em parcelas pendentes/atrasadas)
  - Botão "💬 WhatsApp" (em parcelas pendentes/atrasadas)

**Marcar como pago:**
- Bottom sheet de confirmação com data do pagamento (padrão: hoje, editável)
- Campo de observação opcional
- Chama `POST /installments/{id}/pay`
- Se for a última parcela, o backend já atualiza `sales.status = 'quitado'`

---

### Parcelas — Visão Geral
Abas — todas carregadas via `GET /installments?status=...`:
- **Hoje** — parcelas com vencimento hoje
- **Vencidas** — parcelas atrasadas (ordenadas da mais antiga)
- **Próximos 7 dias** — parcelas pendentes dos próximos 7 dias
- **Todas** — todas as parcelas com filtro de busca

Cada card: nome da cliente, nº parcela/total, valor, data, status, botões de ação.

---

### Produtos — Catálogo

**Lista de produtos:**
- Tabs por categoria: Todas / Roupas Femininas / Roupas Masculinas / Infantil / Cama Mesa Banho / Calçados / Bolsas e Acessórios / Outros
- Busca por nome, marca ou referência
- Card de cada produto: nome, categoria, preço sugerido, badge ativo/inativo
- FAB (+) para cadastrar novo produto

**Formulário de cadastro / edição — campos:**

| Campo | Tipo | Obrigatório |
|---|---|---|
| Nome do produto | Texto | ✅ |
| Categoria | Dropdown | ✅ |
| Preço sugerido | Valor monetário | ✅ |
| Tamanho | Texto livre (P, M, G, 38, único...) | ❌ |
| Cor | Texto livre | ❌ |
| Marca | Texto livre | ❌ |
| Referência / código | Texto livre | ❌ |
| Descrição | Texto longo | ❌ |
| Ativo | Toggle | ✅ |

> Produtos inativos não aparecem na busca ao criar nova venda, mas ficam preservados no histórico.

---

### Relatórios
- Seletor de período: Este mês / Últimos 3 meses / Este ano / Personalizado
- Métricas: Total faturado, Total recebido, Total em aberto, Ticket médio por venda
- Lista "Maiores devedoras" com saldo de cada uma
- Lista "Produtos mais vendidos" por quantidade
- Botão "Exportar PDF" — gera relatório com `pdf` package do Flutter

---

## DESIGN VISUAL

**Paleta de cores:**
```dart
// Cores principais
const terracota    = Color(0xFFC45E3E);  // primária — botões, destaques
const bege         = Color(0xFFF5EFE6);  // fundo dos cards
const offWhite     = Color(0xFFFAFAFA);  // fundo geral
const verdeMUsgo   = Color(0xFF4A7C59);  // status positivo / pago
const vermelhoSuave = Color(0xFFD64040); // status negativo / atrasado
const amareloAlerta = Color(0xFFE8A020); // aviso / vencendo
const cinzaTexto   = Color(0xFF4A4A4A);  // texto principal
const cinzaMuted   = Color(0xFF9E9E9E);  // texto secundário
```

**Tipografia:** Google Fonts — `Nunito` (títulos e labels) + `Nunito Sans` (corpo e campos)

**Visual:**
- Cards com `borderRadius: 16px`, sombra suave `BoxShadow(blurRadius: 8, opacity: 0.08)`
- Bottom Navigation Bar com 5 itens: Dashboard | Clientes | ➕ Nova Venda | Parcelas | Mais
- O item "Nova Venda" (central) tem destaque com botão elevado na cor terracota
- Badges de status: pill arredondado com cor de fundo suave + texto escuro
- Tela de loading: Shimmer em todos os cards

---

## DEPENDÊNCIAS (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Autenticação (apenas auth — sem uso do banco direto)
  supabase_flutter: ^2.0.0

  # HTTP para chamar o backend FastAPI
  http: ^1.2.0

  # Navegação
  go_router: ^13.0.0

  # UI
  google_fonts: ^6.0.0
  shimmer: ^3.0.0
  fl_chart: ^0.66.0           # gráficos nos relatórios

  # Funcionalidades
  url_launcher: ^6.2.0        # abrir WhatsApp e telefone
  image_picker: ^1.0.0        # foto da cliente
  pdf: ^3.10.0                # exportar relatório em PDF
  printing: ^5.12.0           # salvar/imprimir PDF
  flutter_masked_text2: ^0.9.0 # máscaras CPF e telefone
  cached_network_image: ^3.3.0 # cache de fotos
  intl: ^0.19.0               # formatação de moeda e data
```

---

## DADOS DE TESTE — supabase/seed.sql

Crie um seed com:

- **1 usuário admin** (e-mail + senha configuráveis via variável)
- **10 clientes** com nomes e telefones brasileiros realistas (DDD da Bahia — 71/73/74/75/77)
- **8 produtos** distribuídos entre as categorias
- **Cenário de múltiplas compras por cliente:**
  - Cliente "Maria Silva": compra em out/2025 (R$ 500, 5x) + compra em fev/2026 (R$ 200, 2x)
  - Pagamento da parcela 1 da primeira compra já registrado em mar/2026
  - Parcela 2 da primeira compra vencida e não paga (para testar inadimplência)
  - Segunda compra com todas as parcelas pendentes
- **Mix de status:** clientes quitadas, em dia e com atraso
- **Parcelas com vencimento em datas variadas:** algumas hoje, algumas vencidas, algumas futuras

---

## CONFIGURAÇÃO DO AMBIENTE

### Instalar dependências

```bash
# Python 3.11+
pip install -r backend/requirements.txt

# Flutter 3.x
flutter pub get

# Supabase CLI
npm install -g supabase
```

### Inicializar o projeto

```bash
mkdir vendas-app && cd vendas-app
supabase init
flutter create app
mkdir backend
```

### Rodar Supabase localmente

```bash
supabase start
# Exibe: API URL, anon key, service_role key — copie para backend/.env e app/
```

### Aplicar migrations e seed

```bash
supabase db reset
# Aplica migrations + seed automaticamente
```

### Rodar o backend

```bash
cd backend
uvicorn main:app --reload --port 8000
# Documentação interativa: http://localhost:8000/docs
```

### Rodar o app Flutter

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=sua_anon_key_local \
  --dart-define=API_BASE_URL=http://localhost:8000
```

### Deploy para produção

```bash
# 1. Supabase Cloud
supabase link --project-ref SEU_PROJECT_REF
supabase db push

# 2. Backend (Railway ou Render — plano gratuito)
# Configure as variáveis: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SECRET_KEY
# Railway: railway up
# Render: conectar repo e definir start command: uvicorn main:app --host 0.0.0.0 --port $PORT

# 3. App Flutter (build APK)
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua_anon_key_producao \
  --dart-define=API_BASE_URL=https://sua-api.railway.app
```

### README.md — deve incluir:
1. Pré-requisitos: Flutter SDK, Python 3.11+, Supabase CLI, Node.js
2. Passo a passo para rodar localmente (supabase start → db reset → uvicorn → flutter run)
3. Como fazer deploy para produção (Supabase Cloud + Railway/Render + build APK)
4. Estrutura de pastas explicada
5. Variáveis de ambiente necessárias (backend e Flutter)

---

## ORDEM DE IMPLEMENTAÇÃO

Execute nesta sequência e me avise ao terminar cada etapa:

### Fase 1 — Backend
1. Estrutura de pastas do monorepo (`vendas-app/supabase/` + `vendas-app/backend/` + `vendas-app/app/`)
2. `supabase/migrations/001_initial_schema.sql` — schema completo com RLS e índices
3. `supabase/migrations/002_seed_data.sql` — dados de teste com cenário de múltiplas compras por cliente
4. `backend/services/supabase_client.py` + `backend/models/schemas.py`
5. `backend/services/installment_service.py` — geração e atualização de parcelas
6. `backend/routers/auth.py` — middleware de validação de token JWT
7. `backend/routers/customers.py` — CRUD + balance
8. `backend/routers/products.py` — CRUD
9. `backend/routers/sales.py` — criar venda com parcelas
10. `backend/routers/installments.py` — listar + marcar pago + update-overdue
11. `backend/routers/dashboard.py` — métricas + cobranças do dia
12. `backend/routers/settings.py` — configurações
13. `backend/main.py` + `backend/scheduler.py`
14. Testar todas as rotas em `http://localhost:8000/docs`

### Fase 2 — App Flutter
15. Estrutura base: main.dart, theme.dart, router.dart, api_client.dart, formatters
16. Tela de login com persistência de sessão
17. Dashboard com métricas reais + seção de cobranças do dia
18. WhatsApp Helper + integração no dashboard e nas parcelas
19. Módulo Clientes: lista → detalhe (múltiplas compras por cliente) → formulário
20. Nova Venda: stepper completo (busca de produto + item avulso + preview de parcelas)
21. Detalhe da Venda com timeline de parcelas e botão marcar como pago
22. Parcelas: visão geral com abas (Hoje / Vencidas / Próximos 7 dias / Todas)
23. Produtos: catálogo com tabs por categoria + formulário completo
24. Relatórios + exportar PDF

### Fase 3 — Finalização
25. README.md completo
26. Ajustes de UX, tratamento de erros e estados vazios em todas as telas

---

> Comece pela **Fase 1, item 1** — estrutura de pastas do monorepo. Me avise ao terminar cada etapa para seguirmos juntos.
