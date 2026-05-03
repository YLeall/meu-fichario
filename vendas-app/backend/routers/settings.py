from fastapi import APIRouter, Depends, HTTPException
from models.schemas import SettingsUpdate, SettingsResponse
from services.supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter()


def _get_or_create_settings():
    result = supabase.table("settings").select("*").limit(1).execute().data
    if result:
        return result[0]
    return supabase.table("settings").insert({}).execute().data[0]


@router.get("", response_model=SettingsResponse)
def get_settings(user=Depends(get_current_user)):
    return _get_or_create_settings()


@router.put("", response_model=SettingsResponse)
def update_settings(body: SettingsUpdate, user=Depends(get_current_user)):
    current = _get_or_create_settings()
    data    = {k: v for k, v in body.model_dump().items() if v is not None}

    if not data:
        raise HTTPException(400, "Nenhum campo para atualizar")

    result = supabase.table("settings").update(data).eq("id", current["id"]).execute()
    return result.data[0]
