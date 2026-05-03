from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from enum import Enum


class ProductCategory(str, Enum):
    roupa_feminina  = "roupa_feminina"
    roupa_masculina = "roupa_masculina"
    roupa_infantil  = "roupa_infantil"
    cama_mesa_banho = "cama_mesa_banho"
    calcados        = "calcados"
    bolsa_acessorio = "bolsa_acessorio"
    outro           = "outro"


class FormaPagemento(str, Enum):
    pix       = "pix"
    parcelado = "parcelado"


class SaleStatus(str, Enum):
    em_dia   = "em_dia"
    atrasado = "atrasado"
    quitado  = "quitado"


class InstallmentStatus(str, Enum):
    pendente = "pendente"
    pago     = "pago"
    atrasado = "atrasado"


# ── Customers ────────────────────────────────────────────────

class CustomerCreate(BaseModel):
    nome:        str
    telefone:    str
    cpf:         Optional[str] = None
    endereco:    Optional[str] = None
    observacoes: Optional[str] = None
    foto_url:    Optional[str] = None


class CustomerUpdate(BaseModel):
    nome:        Optional[str] = None
    telefone:    Optional[str] = None
    cpf:         Optional[str] = None
    endereco:    Optional[str] = None
    observacoes: Optional[str] = None
    foto_url:    Optional[str] = None
    ativo:       Optional[bool] = None


class CustomerResponse(BaseModel):
    id:          str
    nome:        str
    telefone:    str
    cpf:         Optional[str]
    endereco:    Optional[str]
    observacoes: Optional[str]
    foto_url:    Optional[str]
    ativo:       bool
    created_at:  datetime


class CustomerBalanceResponse(BaseModel):
    customer_id:    str
    nome:           str
    total_em_aberto: Decimal


# ── Products ─────────────────────────────────────────────────

class ProductCreate(BaseModel):
    nome:           str
    categoria:      ProductCategory
    preco_sugerido: Decimal
    descricao:      Optional[str] = None
    tamanho:        Optional[str] = None
    cor:            Optional[str] = None
    marca:          Optional[str] = None
    referencia:     Optional[str] = None
    ativo:          bool = True


class ProductUpdate(BaseModel):
    nome:           Optional[str] = None
    categoria:      Optional[ProductCategory] = None
    preco_sugerido: Optional[Decimal] = None
    descricao:      Optional[str] = None
    tamanho:        Optional[str] = None
    cor:            Optional[str] = None
    marca:          Optional[str] = None
    referencia:     Optional[str] = None
    ativo:          Optional[bool] = None


class ProductResponse(BaseModel):
    id:             str
    nome:           str
    categoria:      str
    preco_sugerido: Optional[Decimal]
    descricao:      Optional[str]
    tamanho:        Optional[str]
    cor:            Optional[str]
    marca:          Optional[str]
    referencia:     Optional[str]
    ativo:          bool
    created_at:     datetime


# ── Sales ────────────────────────────────────────────────────

class SaleItemCreate(BaseModel):
    product_id:      Optional[str] = None
    descricao_livre: Optional[str] = None
    categoria_livre: Optional[str] = None
    quantidade:      int = 1
    preco_unitario:  Decimal


class SaleCreate(BaseModel):
    customer_id:             str
    data_venda:              date = Field(default_factory=date.today)
    forma_pagamento:         FormaPagemento
    total_bruto:             Decimal
    entrada_valor:           Decimal = Decimal("0")
    total_parcelado:         Decimal
    num_parcelas:            int = 1
    data_primeiro_vencimento: date
    observacoes:             Optional[str] = None
    items:                   List[SaleItemCreate]


class SaleItemResponse(BaseModel):
    id:              str
    product_id:      Optional[str]
    descricao_livre: Optional[str]
    categoria_livre: Optional[str]
    quantidade:      int
    preco_unitario:  Decimal
    subtotal:        Decimal


class InstallmentResponse(BaseModel):
    id:               str
    sale_id:          str
    numero_parcela:   int
    total_parcelas:   int
    valor:            Decimal
    data_vencimento:  date
    data_pagamento:   Optional[date]
    status:           str
    whatsapp_enviado: bool
    created_at:       datetime


class SaleResponse(BaseModel):
    id:                       str
    customer_id:              str
    data_venda:               date
    forma_pagamento:          str
    total_bruto:              Decimal
    entrada_valor:            Decimal
    total_parcelado:          Decimal
    num_parcelas:             int
    data_primeiro_vencimento: date
    observacoes:              Optional[str]
    status:                   str
    created_at:               datetime


class SaleDetailResponse(SaleResponse):
    items:        List[SaleItemResponse]
    installments: List[InstallmentResponse]


# ── Installments ─────────────────────────────────────────────

class PaymentCreate(BaseModel):
    data_pagamento: date = Field(default_factory=date.today)
    observacoes:    Optional[str] = None


class PayInstallmentResponse(BaseModel):
    installment:  InstallmentResponse
    sale_status:  str


# ── Dashboard ────────────────────────────────────────────────

class DashboardMetrics(BaseModel):
    total_faturado_mes:     Decimal
    total_recebido_mes:     Decimal
    clientes_com_debito:    int
    parcelas_vencidas:      int
    parcelas_vencendo_hoje: int
    total_em_aberto:        Decimal


class CobrancaItem(BaseModel):
    installment_id:  str
    customer_id:     str
    customer_nome:   str
    customer_tel:    str
    numero_parcela:  int
    total_parcelas:  int
    valor:           Decimal
    data_vencimento: date
    dias_atraso:     int
    status:          str
    whatsapp_enviado: bool


# ── Settings ─────────────────────────────────────────────────

class SettingsUpdate(BaseModel):
    chave_pix:      Optional[str] = None
    nome_vendedora: Optional[str] = None


class SettingsResponse(BaseModel):
    id:             str
    chave_pix:      Optional[str]
    nome_vendedora: Optional[str]
    updated_at:     datetime
