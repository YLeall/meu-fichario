from datetime import date
from dateutil.relativedelta import relativedelta
from services.supabase_client import supabase


def generate_installments(sale_id: str):
    """Gera todas as parcelas de uma venda."""
    sale = supabase.table("sales").select("*").eq("id", sale_id).single().execute().data

    total  = float(sale["total_parcelado"])
    n      = sale["num_parcelas"]
    data_base = date.fromisoformat(sale["data_primeiro_vencimento"])

    valor_base = round(total / n, 2)
    ajuste     = round(total - valor_base * n, 2)

    installments = []
    for i in range(n):
        valor      = round(valor_base + (ajuste if i == n - 1 else 0), 2)
        data_venc  = data_base + relativedelta(months=i)
        installments.append({
            "sale_id":         sale_id,
            "numero_parcela":  i + 1,
            "total_parcelas":  n,
            "valor":           valor,
            "data_vencimento": data_venc.isoformat(),
            "status":          "pendente",
        })

    return supabase.table("installments").insert(installments).execute().data


def update_overdue():
    """Marca parcelas vencidas como atrasadas e atualiza status das vendas."""
    hoje = date.today().isoformat()

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

    ids      = [p["id"] for p in parcelas]
    sale_ids = list({p["sale_id"] for p in parcelas})

    supabase.table("installments").update({"status": "atrasado"}).in_("id", ids).execute()

    for sale_id in sale_ids:
        todas = (
            supabase.table("installments")
            .select("status")
            .eq("sale_id", sale_id)
            .execute()
            .data or []
        )
        todas_pagas     = all(p["status"] == "pago" for p in todas)
        alguma_atrasada = any(p["status"] == "atrasado" for p in todas)
        novo_status     = "quitado" if todas_pagas else "atrasado" if alguma_atrasada else "em_dia"
        supabase.table("sales").update({"status": novo_status}).eq("id", sale_id).execute()

    return {"parcelas_atualizadas": len(ids), "vendas_atualizadas": len(sale_ids)}
