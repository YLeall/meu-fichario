from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from models.schemas import SaleCreate, SaleDetailResponse
from services.supabase_client import supabase
from services.installment_service import generate_installments
from routers.auth import get_current_user

router = APIRouter()


@router.get("")
def list_sales(
    customer_id: Optional[str]  = Query(None),
    status:      Optional[str]  = Query(None),
    limit:       Optional[int]  = Query(None),
    user=Depends(get_current_user),
):
    q = (
        supabase.table("sales")
        .select("*, customers(nome, telefone)")
        .order("created_at", desc=True)
    )
    if customer_id:
        q = q.eq("customer_id", customer_id)
    if status:
        q = q.eq("status", status)
    if limit:
        q = q.limit(limit)

    result = q.execute().data or []
    # Flatten customer name
    for s in result:
        if s.get("customers"):
            s["customer_nome"] = s["customers"].get("nome")
    return result


@router.post("", status_code=201)
def create_sale(body: SaleCreate, user=Depends(get_current_user)):
    if not body.items:
        raise HTTPException(400, "A venda deve ter pelo menos um item")

    # 1. Inserir venda
    sale_data = body.model_dump(exclude={"items"})
    sale_data["data_venda"]               = sale_data["data_venda"].isoformat()
    sale_data["data_primeiro_vencimento"] = sale_data["data_primeiro_vencimento"].isoformat()
    sale_data["total_bruto"]              = float(sale_data["total_bruto"])
    sale_data["entrada_valor"]            = float(sale_data["entrada_valor"])
    sale_data["total_parcelado"]          = float(sale_data["total_parcelado"])

    sale = supabase.table("sales").insert(sale_data).execute().data[0]
    sale_id = sale["id"]

    # 2. Inserir itens
    items_data = []
    for item in body.items:
        d = item.model_dump()
        d["sale_id"]        = sale_id
        d["preco_unitario"] = float(d["preco_unitario"])
        items_data.append(d)

    supabase.table("sale_items").insert(items_data).execute()

    # 3. Gerar parcelas
    installments = generate_installments(sale_id)

    # 4. Retornar venda completa
    items = supabase.table("sale_items").select("*").eq("sale_id", sale_id).execute().data or []
    return {**sale, "items": items, "installments": installments}


@router.get("/{sale_id}")
def get_sale(sale_id: str, user=Depends(get_current_user)):
    sale = supabase.table("sales").select("*").eq("id", sale_id).single().execute().data
    if not sale:
        raise HTTPException(404, "Venda não encontrada")

    items        = supabase.table("sale_items").select("*").eq("sale_id", sale_id).execute().data or []
    installments = (
        supabase.table("installments")
        .select("*")
        .eq("sale_id", sale_id)
        .order("numero_parcela")
        .execute()
        .data or []
    )

    return {**sale, "items": items, "installments": installments}
