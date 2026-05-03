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

app.include_router(auth.router,         prefix="/auth",         tags=["auth"])
app.include_router(customers.router,    prefix="/customers",    tags=["customers"])
app.include_router(products.router,     prefix="/products",     tags=["products"])
app.include_router(sales.router,        prefix="/sales",        tags=["sales"])
app.include_router(installments.router, prefix="/installments", tags=["installments"])
app.include_router(dashboard.router,    prefix="/dashboard",    tags=["dashboard"])
app.include_router(settings.router,     prefix="/settings",     tags=["settings"])


@app.on_event("startup")
async def startup():
    start_scheduler()


@app.get("/health")
def health():
    return {"status": "ok"}
