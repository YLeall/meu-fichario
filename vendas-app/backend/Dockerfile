FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" "supabase==2.7.4" \
    supafunc websockets httpx httpcore python-dotenv pydantic \
    "apscheduler==3.10.4" python-dateutil

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
