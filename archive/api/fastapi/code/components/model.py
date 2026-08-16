import mlflow
import mlflow.pyfunc
import pickle
import os
import logging

logger = logging.getLogger("main")

def load_model(model_name:str, stage:str, cache_folder:str) -> mlflow.pyfunc.PyFuncModel:
    model:mlflow.pyfunc.PyFuncModel = None # type:ignore

    # Check if cache
    model_path = os.path.join(cache_folder,f"{model_name}_{stage}")
    if(os.path.exists(model_path) == True):
        logger.debug(f"Found model from {model_path=}. Load from cache.")
        with open(file=model_path, mode='rb') as file:
            model = pickle.load(file)

    else:
        # Load from mlflow registry
        model_uri:str = f"models:/{model_name}/{stage}"
        logger.debug(f"Load model from {model_uri=}.")
        model = mlflow.pyfunc.load_model(model_uri=model_uri)
        # Save to cache
        with open(file=model_path, mode='wb') as file:
            logger.debug(f"Save model to {model_path=}.")
            pickle.dump(model, file)

    return model