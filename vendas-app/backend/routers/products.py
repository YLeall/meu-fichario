from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from models.schemas import ProductCreate, ProductUpdate, ProductResponse
from services.supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter()


@router.get("", response_model=list[ProductResponse])
def list_products(
    busca:     Optional[str] = Query(None),
    categoria: Optional[str] = Query(None),
    ativo:     Optional[bool] = Query(None),
    user=Depends(get_current_user),
):
    q = supabase.table("products").select("*").order("nome")

    if busca:
        q = q.or_(f"nome.ilike.%{busca}%,marca.ilike.%{busca}%,referencia.ilike.%{busca}%")
    if categoria:
        q = q.eq("categoria", categoria)
    if ativo is not None:
        q = q.eq("ativo", ativo)

    return q.execute().data or []


@router.post("", response_model=ProductResponse, status_code=201)
def create_product(body: ProductCreate, user=Depends(get_current_user)):
    data   = body.model_dump()
    result = supabase.table("products").insert(data).execute()
    return result.data[0]


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(product_id: str, body: ProductUpdate, user=Depends(get_current_user)):
    data = {k: v for k, v in body.model_dump().items() if v is not None}
    if not data:
        raise HTTPException(400, "Nenhum campo para atualizar")

    result = supabase.table("products").update(data).eq("id", product_id).execute()
    if not result.data:
        raise HTTPException(404, "Produto não encontrado")
    return result.data[0]


@router.delete("/{product_id}", status_code=204)
def deactivate_product(product_id: str, user=Depends(get_current_user)):
    result = supabase.table("products").update({"ativo": False}).eq("id", product_id).execute()
    if not result.data:
        raise HTTPException(404, "Produto não encontrado")
