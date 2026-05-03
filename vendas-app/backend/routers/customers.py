from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from models.schemas import CustomerCreate, CustomerUpdate, CustomerResponse, CustomerBalanceResponse
from services.supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter()


@router.get("", response_model=list[CustomerResponse])
def list_customers(
    busca:  Optional[str]  = Query(None, description="Busca por nome ou telefone"),
    status: Optional[str]  = Query(None, description="ativo, inativo"),
    user=Depends(get_current_user),
):
    q = supabase.table("customers").select("*").order("nome")

    if busca:
        q = q.or_(f"nome.ilike.%{busca}%,telefone.ilike.%{busca}%")

    if status == "ativo":
        q = q.eq("ativo", True)
    elif status == "inativo":
        q = q.eq("ativo", False)

    result = q.execute()
    return result.data or []


@router.post("", response_model=CustomerResponse, status_code=201)
def create_customer(body: CustomerCreate, user=Depends(get_current_user)):
    # Remover não-dígitos do telefone e CPF
    telefone = "".join(c for c in body.telefone if c.isdigit())
    cpf      = "".join(c for c in body.cpf if c.isdigit()) if body.cpf else None

    data = body.model_dump()
    data["telefone"] = telefone
    data["cpf"]      = cpf

    result = supabase.table("customers").insert(data).execute()
    return result.data[0]


@router.get("/{customer_id}/balance", response_model=CustomerBalanceResponse)
def get_balance(customer_id: str, user=Depends(get_current_user)):
    customer = supabase.table("customers").select("id, nome").eq("id", customer_id).single().execute().data
    if not customer:
        raise HTTPException(404, "Cliente não encontrada")

    sales = (
        supabase.table("sales")
        .select("id")
        .eq("customer_id", customer_id)
        .execute()
        .data or []
    )
    sale_ids = [s["id"] for s in sales]

    total = 0.0
    if sale_ids:
        parcelas = (
            supabase.table("installments")
            .select("valor")
            .in_("sale_id", sale_ids)
            .in_("status", ["pendente", "atrasado"])
            .execute()
            .data or []
        )
        total = sum(float(p["valor"]) for p in parcelas)

    return {"customer_id": customer_id, "nome": customer["nome"], "total_em_aberto": total}


@router.get("/{customer_id}", response_model=dict)
def get_customer(customer_id: str, user=Depends(get_current_user)):
    customer = (
        supabase.table("customers").select("*").eq("id", customer_id).single().execute().data
    )
    if not customer:
        raise HTTPException(404, "Cliente não encontrada")

    sales = (
        supabase.table("sales")
        .select("*, sale_items(*), installments(*)")
        .eq("customer_id", customer_id)
        .order("data_venda", desc=True)
        .execute()
        .data or []
    )

    return {**customer, "sales": sales}


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(customer_id: str, body: CustomerUpdate, user=Depends(get_current_user)):
    data = {k: v for k, v in body.model_dump().items() if v is not None}
    if not data:
        raise HTTPException(400, "Nenhum campo para atualizar")

    if "telefone" in data:
        data["telefone"] = "".join(c for c in data["telefone"] if c.isdigit())
    if "cpf" in data:
        data["cpf"] = "".join(c for c in data["cpf"] if c.isdigit())

    result = supabase.table("customers").update(data).eq("id", customer_id).execute()
    if not result.data:
        raise HTTPException(404, "Cliente não encontrada")
    return result.data[0]
