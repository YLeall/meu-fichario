from fastapi import APIRouter, Depends
from datetime import date
from services.supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter()


@router.get("/metrics")
def get_metrics(user=Depends(get_current_user)):
    hoje    = date.today()
    mes_ini = hoje.replace(day=1).isoformat()
    mes_fim = hoje.isoformat()

    # Total faturado no mês (soma de total_bruto de vendas criadas no mês)
    vendas_mes = (
        supabase.table("sales")
        .select("total_bruto, total_parcelado")
        .gte("data_venda", mes_ini)
        .lte("data_venda", mes_fim)
        .execute()
        .data or []
    )
    total_faturado_mes = sum(float(v["total_bruto"]) for v in vendas_mes)

    # Total recebido no mês (pagamentos registrados no mês)
    pagamentos_mes = (
        supabase.table("payments")
        .select("valor_pago")
        .gte("data_pagamento", mes_ini)
        .lte("data_pagamento", mes_fim)
        .execute()
        .data or []
    )
    total_recebido_mes = sum(float(p["valor_pago"]) for p in pagamentos_mes)

    # Parcelas vencidas
    vencidas = (
        supabase.table("installments")
        .select("id", count="exact")
        .eq("status", "atrasado")
        .execute()
    )
    parcelas_vencidas = vencidas.count or 0

    # Parcelas vencendo hoje
    vencendo_hoje = (
        supabase.table("installments")
        .select("id", count="exact")
        .eq("data_vencimento", hoje.isoformat())
        .eq("status", "pendente")
        .execute()
    )
    parcelas_vencendo_hoje = vencendo_hoje.count or 0

    # Total em aberto (todas as parcelas pendentes + atrasadas)
    em_aberto = (
        supabase.table("installments")
        .select("valor")
        .in_("status", ["pendente", "atrasado"])
        .execute()
        .data or []
    )
    total_em_aberto = sum(float(p["valor"]) for p in em_aberto)

    # Clientes com débito
    sales_com_debito = (
        supabase.table("installments")
        .select("sales(customer_id)")
        .in_("status", ["pendente", "atrasado"])
        .execute()
        .data or []
    )
    customer_ids_unicos = {
        r["sales"]["customer_id"]
        for r in sales_com_debito
        if r.get("sales") and r["sales"].get("customer_id")
    }
    clientes_com_debito = len(customer_ids_unicos)

    return {
        "total_faturado_mes":     round(total_faturado_mes, 2),
        "total_recebido_mes":     round(total_recebido_mes, 2),
        "clientes_com_debito":    clientes_com_debito,
        "parcelas_vencidas":      parcelas_vencidas,
        "parcelas_vencendo_hoje": parcelas_vencendo_hoje,
        "total_em_aberto":        round(total_em_aberto, 2),
    }


@router.get("/today")
def get_today_charges(user=Depends(get_current_user)):
    hoje = date.today()

    # Parcelas de hoje (pendentes) + parcelas atrasadas
    result = (
        supabase.table("installments")
        .select("*, sales(customer_id, customers(nome, telefone))")
        .or_(
            f"and(data_vencimento.eq.{hoje.isoformat()},status.eq.pendente),"
            f"status.eq.atrasado"
        )
        .order("data_vencimento")
        .execute()
        .data or []
    )

    cobrancas = []
    for r in result:
        sale     = r.get("sales") or {}
        customer = sale.get("customers") or {}
        venc     = date.fromisoformat(r["data_vencimento"])
        atraso   = max((hoje - venc).days, 0)

        cobrancas.append({
            "installment_id":   r["id"],
            "customer_id":      sale.get("customer_id", ""),
            "customer_nome":    customer.get("nome", ""),
            "customer_tel":     customer.get("telefone", ""),
            "numero_parcela":   r["numero_parcela"],
            "total_parcelas":   r["total_parcelas"],
            "valor":            float(r["valor"]),
            "data_vencimento":  r["data_vencimento"],
            "dias_atraso":      atraso,
            "status":           r["status"],
            "whatsapp_enviado": r["whatsapp_enviado"],
        })

    return cobrancas
