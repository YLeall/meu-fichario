from fastapi import APIRouter, Depends, HTTPException, Query
from datetime import date, timedelta
from typing import Optional
from models.schemas import PaymentCreate
from services.supabase_client import supabase
from services.installment_service import update_overdue
from routers.auth import get_current_user

router = APIRouter()


@router.get("")
def list_installments(
    status:   Optional[str]  = Query(None, description="pendente, pago, atrasado"),
    busca:    Optional[str]  = Query(None, description="Busca por nome da cliente"),
    data_ini: Optional[date] = Query(None),
    data_fim: Optional[date] = Query(None),
    user=Depends(get_current_user),
):
    q = (
        supabase.table("installments")
        .select("*, sales(customer_id, customers(nome, telefone))")
        .order("data_vencimento")
    )

    if status:
        q = q.eq("status", status)
    if data_ini:
        q = q.gte("data_vencimento", data_ini.isoformat())
    if data_fim:
        q = q.lte("data_vencimento", data_fim.isoformat())

    result = q.execute().data or []

    if busca:
        busca_lower = busca.lower()
        result = [
            r for r in result
            if busca_lower in (r.get("sales", {}) or {}).get("customers", {}).get("nome", "").lower()
        ]

    return result


@router.post("/{installment_id}/pay")
def pay_installment(installment_id: str, body: PaymentCreate, user=Depends(get_current_user)):
    installment = (
        supabase.table("installments").select("*").eq("id", installment_id).single().execute().data
    )
    if not installment:
        raise HTTPException(404, "Parcela não encontrada")
    if installment["status"] == "pago":
        raise HTTPException(400, "Parcela já está paga")

    # Registrar pagamento
    supabase.table("payments").insert({
        "installment_id": installment_id,
        "valor_pago":     float(installment["valor"]),
        "data_pagamento": body.data_pagamento.isoformat(),
        "observacoes":    body.observacoes,
    }).execute()

    # Atualizar parcela
    updated = supabase.table("installments").update({
        "status":          "pago",
        "data_pagamento":  body.data_pagamento.isoformat(),
    }).eq("id", installment_id).execute().data[0]

    # Verificar se todas as parcelas da venda foram pagas
    sale_id  = installment["sale_id"]
    todas    = supabase.table("installments").select("status").eq("sale_id", sale_id).execute().data or []
    todas_pagas = all(p["status"] == "pago" for p in todas)

    if todas_pagas:
        supabase.table("sales").update({"status": "quitado"}).eq("id", sale_id).execute()
        sale_status = "quitado"
    else:
        alguma_atrasada = any(p["status"] == "atrasado" for p in todas)
        sale_status = "atrasado" if alguma_atrasada else "em_dia"

    return {"installment": updated, "sale_status": sale_status}


@router.post("/update-overdue")
def trigger_update_overdue(user=Depends(get_current_user)):
    return update_overdue()
