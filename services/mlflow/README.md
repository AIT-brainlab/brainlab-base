# MLflow Experiment Tracking Service (`services/mlflow`)

## Overview
AIT Brainlab hosts a central MLflow tracking server for logging hyperparameters, model training metrics, PyTorch/TensorFlow checkpoints, and evaluation artifacts across lab research projects.

---

## 🏗 Service Configuration
- **Default Tracking Server URI**: `http://tokyo.cs.ait.ac.th:5000` (or internal NetBird IP: `http://100.x.x.x:5000`)
- **Artifact Storage**: TrueNAS shared volume (`/mnt/HDD/home/shared/mlruns`) or GCP Cloud Storage bucket (`gs://ait-brainlab-mlruns`).
- **Backend Store**: SQLite (`sqlite:///mlflow.db`) or PostgreSQL.

---

## 🚀 Starting the MLflow Server

```bash
mlflow server \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root /mnt/HDD/home/shared/mlruns \
    --host 0.0.0.0 \
    --port 5000
```

---

## 🐍 Client Integration in Research Notebooks

```python
import mlflow
import mlflow.pytorch

# Connect to Brainlab central tracking server
mlflow.set_tracking_uri("http://tokyo.cs.ait.ac.th:5000")
mlflow.set_experiment("nlp-transformer-finetune")

with mlflow.start_run():
    mlflow.log_param("learning_rate", 1e-4)
    mlflow.log_param("batch_size", 32)
    
    # During training:
    mlflow.log_metric("loss", 0.245, step=1)
    mlflow.log_metric("accuracy", 0.942, step=1)
```

See [`examples/mlflow-example.ipynb`](../../examples/mlflow-example.ipynb) for a complete end-to-end tutorial.
