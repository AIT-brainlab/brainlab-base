from components.logger import init_logger
from components.model import load_model 
import logging
import os

import mlflow
import mlflow.pyfunc

from typing import Union
import uvicorn as uvicorn
from fastapi import FastAPI, APIRouter, UploadFile
from fastapi.middleware.cors import CORSMiddleware

# A bunch of global variable
MODEL_NAME:str = "mlflow-example"
STAGE:str = "Production"
MLFLOW_URL:str = "http://la.cs.ait.ac.th"
CACHE_FOLDER:str = os.path.join("/root","cache")
MODEL:mlflow.pyfunc.PyFuncModel

router = APIRouter(prefix="")


@router.get("/")
def get_root():
    return {"name": "brainlab-fastapi-example"}

@router.post("/predict/")
async def create_upload_file(file: UploadFile):
    from torchvision import transforms
    from PIL import Image
    import io
    # Super quick dirty way to read file and cast into PILimage
    image = Image.open(io.BytesIO(file.file.read()))
    preprocess = transforms.Compose([
        transforms.Resize((256,256)),
        transforms.CenterCrop((224,224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.5], std=[0.5]),
    ])
    image = preprocess(image).numpy().reshape(1,1,224,224)
    answer = dict({})
    answer['status'] = 'ok'
    answer['code'] = 200
    answer['predict'] = int(MODEL.predict(image).argmax())
    return answer

def create_app():
    app = FastAPI()
    app.include_router(router)

    origins = [
        "*",
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    return app

def main():
    global MODEL
    # Init Logger
    init_logger(name="main", filename="main", path="/root/logs/", level=logging.DEBUG)
    logger = logging.getLogger(name="main")
    # Now prepare model
    mlflow.set_tracking_uri(MLFLOW_URL)
    MODEL = load_model(model_name=MODEL_NAME, stage=STAGE, cache_folder=CACHE_FOLDER)

    # init FastAPI
    app = create_app()
    logger.info("Start API")
    return app

if __name__ == '__main__':
    # We use main() as a wrap function to spawn FastAPI app
    app = main()
    # If you run this file with `python3 main.py`.
    # this section will run. Thus, a Uvicorn sever spawns in the port 8080.
    # Which is not the same port as the production port (80).
    # This is mainly for development purpose.
    # So you don't need traefik to access the API.
    uvicorn.run(app="main:main", host="0.0.0.0", port=8080, workers=1, reload=True)
    # Remember that FastAPI provides an interface to test out your API
    # http://localhost:9000/docs