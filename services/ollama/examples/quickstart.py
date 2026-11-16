"""
AIT Brainlab - Ollama over NetBird Quickstart Script
Demonstrates model management, inference, switching, and keep-alive configuration.
"""

from ollama import Client
import pandas as pd

# Connect to server 'la' over NetBird MagicDNS
# (If inside a JupyterHub container on 'la', use 'http://ollama:11434')
OLLAMA_HOST = "http://la:11434"
client = Client(host=OLLAMA_HOST)
print(f"Connected to Ollama at {OLLAMA_HOST}\n")

# ------------------------------------------------------------------------------
# 1. List Available Models
# ------------------------------------------------------------------------------
print("=== 1. Downloaded Models on Server ===")
models_resp = client.list()
for m in models_resp.get("models", []):
    size = (m.get("size") if isinstance(m, dict) else getattr(m, "size", 0)) or 0
    size_gb = size / (1024 ** 3)
    name = (m.get("model") or m.get("name")) if isinstance(m, dict) else (getattr(m, "model", None) or getattr(m, "name", "N/A"))
    print(f"• {name} ({size_gb:.2f} GB)")
print()

# ------------------------------------------------------------------------------
# 2. See Active (Loaded) Models in GPU VRAM
# ------------------------------------------------------------------------------
print("=== 2. Active Models & Available VRAM ===")
OLLAMA_VRAM_BUDGET_GB = 44.0
ps_resp = client.ps()
active = ps_resp.get("models", [])

total_vram_used = sum((m.get("size_vram") if isinstance(m, dict) else getattr(m, "size_vram", 0)) or 0 for m in active)
total_vram_used_gb = total_vram_used / (1024 ** 3)
available_vram_gb = max(0.0, OLLAMA_VRAM_BUDGET_GB - total_vram_used_gb)

print(f"📊 Budget: {OLLAMA_VRAM_BUDGET_GB:.2f} GB | Used: {total_vram_used_gb:.2f} GB | Available: {available_vram_gb:.2f} GB")
if active:
    for m in active:
        size_vram_gb = ((m.get("size_vram") if isinstance(m, dict) else getattr(m, "size_vram", 0)) or 0) / (1024 ** 3)
        print(f"• {m.get('name')}: {size_vram_gb:.2f} GB VRAM (Expires at {m.get('expires_at')})")
else:
    print("ℹ️ No models currently loaded in GPU VRAM (idle). Full 44.00 GB available.")
print()

# ------------------------------------------------------------------------------
# 3. Download / Pull a Model
# ------------------------------------------------------------------------------
TARGET_MODEL = "llama3.2:1b"
print(f"=== 3. Pulling '{TARGET_MODEL}' ===")
for chunk in client.pull(TARGET_MODEL, stream=True):
    status = chunk.get("status", "") if isinstance(chunk, dict) else getattr(chunk, "status", "")
    total = (chunk.get("total") if isinstance(chunk, dict) else getattr(chunk, "total", 0)) or 0
    completed = (chunk.get("completed") if isinstance(chunk, dict) else getattr(chunk, "completed", 0)) or 0

    if total > 0:
        pct = (completed / total) * 100
        print(f"\r{status}: {pct:5.1f}% ({completed / 1024**2:.1f} MB / {total / 1024**2:.1f} MB)", end="", flush=True)
    else:
        print(f"\r{status}...", end="", flush=True)
print("\n✅ Pull complete.\n")

# ------------------------------------------------------------------------------
# 4. Select / Switch Model (Explicit Unload)
# ------------------------------------------------------------------------------
print(f"=== 4. Selecting Model: {TARGET_MODEL} ===")
# Unload any previously running models (keep_alive=0 instantly evicts from VRAM)
for m in client.ps().get("models", []):
    name = m.get("name") or m.get("model")
    client.generate(model=name, prompt="", keep_alive=0)
    print(f"🗑️ Evicted '{name}' from GPU VRAM.")
print(f"🎯 Ready with '{TARGET_MODEL}'.\n")

# ------------------------------------------------------------------------------
# 5. Use the Model (Streaming)
# ------------------------------------------------------------------------------
print(f"=== 5. Prompting '{TARGET_MODEL}' ===")
messages = [
    {"role": "system", "content": "You are a concise AI research assistant in AIT Brainlab."},
    {"role": "user", "content": "Explain the difference between full fine-tuning and LoRA in 2 bullet points."}
]

stream = client.chat(
    model=TARGET_MODEL,
    messages=messages,
    options={"num_ctx": 4096},  # Bound context window to prevent VRAM spikes
    stream=True
)
for chunk in stream:
    print(chunk["message"]["content"], end="", flush=True)
print("\n")

# ------------------------------------------------------------------------------
# 6. Change Parameters & Keep-Alive (Make Model Active Longer)
# ------------------------------------------------------------------------------
print("=== 6. Using Custom Options & 1-Hour Keep-Alive ===")
response = client.chat(
    model=TARGET_MODEL,
    messages=[
        {"role": "user", "content": "Write a haiku about GPU clusters in an academic lab."}
    ],
    options={
        "temperature": 0.2,    # Deterministic output
        "top_p": 0.9,
        "num_ctx": 4096,       # 4k context window
    },
    keep_alive="1h"            # Keep loaded in GPU VRAM for 1 hour!
)
print(response["message"]["content"])
print()

# Verify updated VRAM status
print("=== Updated Active VRAM Status ===")
for m in client.ps().get("models", []):
    vram_gb = m.get("size_vram", 0) / (1024 ** 3)
    print(f"• Model: {m.get('name')} | VRAM: {vram_gb:.2f} GB | Expires At: {m.get('expires_at')}")
