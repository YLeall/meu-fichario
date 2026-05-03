# Vendas App

App mobile de gestão de vendas para vendedora autônoma.

**Stack:** Flutter (frontend) + FastAPI (backend) + Supabase (banco PostgreSQL + auth)

---

## Pré-requisitos

- Python 3.11+
- Flutter SDK 3.x
- Supabase CLI (`npm install -g supabase`)
- Node.js (para o Supabase CLI)

---

## Rodando localmente

### 1. Banco de dados (Supabase local)

```bash
cd vendas-app/supabase
supabase start
# Copie: API URL, anon key e service_role key exibidos
supabase db reset
# Aplica as migrations (schema + seed) automaticamente
```

### 2. Backend (FastAPI)

```bash
cd vendas-app/backend
cp .env.example .env
# Edite .env com as chaves do supabase start
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# Documentação em: http://localhost:8000/docs
```

### 3. App Flutter

```bash
cd vendas-app/app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY \
  --dart-define=API_BASE_URL=http://localhost:8000
```

---

## Deploy para produção

### 1. Supabase Cloud

```bash
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

### 2. Backend (Railway)

```bash
railway login && railway init && railway up
# Defina as variáveis no painel Railway:
# SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SECRET_KEY
```

**Render:** Build command: `pip install -r requirements.txt`
Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### 3. App Flutter (build APK)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY_PRODUCAO \
  --dart-define=API_BASE_URL=https://sua-api.railway.app
```

---

## Estrutura do projeto

```
vendas-app/
  backend/          # API FastAPI (Python)
    routers/        # Endpoints por domínio
    services/       # Lógica de negócio e cliente Supabase
    models/         # Schemas Pydantic
    main.py         # Entry point
    scheduler.py    # Job diário de atualização de parcelas vencidas
  supabase/
    migrations/     # 001_initial_schema.sql + 002_seed_data.sql
  app/              # App Flutter
    lib/
      core/         # theme, router, api_client, utils
      features/     # auth, dashboard, customers, sales, installments, products, reports
```

## Variáveis de ambiente

### Backend (`backend/.env`)

| Variável                  | Descrição                          |
|---------------------------|------------------------------------|
| `SUPABASE_URL`            | URL do projeto Supabase            |
| `SUPABASE_SERVICE_ROLE_KEY` | Chave service_role (acesso total) |
| `SECRET_KEY`              | Segredo para verificação de JWT    |

### Flutter (`--dart-define`)

| Variável         | Descrição                      |
|-----------------|--------------------------------|
| `SUPABASE_URL`  | URL do projeto Supabase        |
| `SUPABASE_ANON_KEY` | Chave anon do Supabase     |
| `API_BASE_URL`  | URL base do backend FastAPI    |
