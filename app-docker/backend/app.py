
import os
from typing import List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "tasksdb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

OTEL_EXPORTER_OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Create schema if not exists
with engine.begin() as conn:
    conn.execute(text("""
    CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );
    """))

class TaskIn(BaseModel):
    title: str
    description: str | None = None

class Task(BaseModel):
    id: int
    title: str
    description: str | None = None

app = FastAPI(title="Tasks API")

# OpenTelemetry tracing (optional)
if OTEL_EXPORTER_OTLP_ENDPOINT:
    resource = Resource.create({"service.name": "tasks-backend"})
    tracer_provider = TracerProvider(resource=resource)
    span_exporter = OTLPSpanExporter(endpoint=OTEL_EXPORTER_OTLP_ENDPOINT)
    tracer_provider.add_span_processor(BatchSpanProcessor(span_exporter))
    trace.set_tracer_provider(tracer_provider)
    FastAPIInstrumentor.instrument_app(app)

@app.get("/healthz")
def healthz():
    try:
        with engine.begin() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}
    except OperationalError:
        raise HTTPException(status_code=500, detail="DB not reachable")

@app.post("/addTask")
def add_task(task: TaskIn):
    with engine.begin() as conn:
        res = conn.execute(
            text("INSERT INTO tasks (title, description) VALUES (:t, :d) RETURNING id"),
            {"t": task.title, "d": task.description},
        )
        new_id = res.scalar_one()
    return {"id": new_id, "message": "created"}

@app.delete("/deleteTask/{task_id}")
def delete_task(task_id: int):
    with engine.begin() as conn:
        res = conn.execute(text("DELETE FROM tasks WHERE id=:id RETURNING id"), {"id": task_id})
        row = res.first()
    if not row:
        raise HTTPException(status_code=404, detail="not found")
    return {"id": task_id, "message": "deleted"}

@app.get("/listTasks", response_model=List[Task])
def list_tasks():
    with engine.begin() as conn:
        rows = conn.execute(text("SELECT id, title, description FROM tasks ORDER BY id DESC")).all()
    return [Task(id=r.id, title=r.title, description=r.description) for r in rows]
