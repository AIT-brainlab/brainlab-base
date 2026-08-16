import logging
import logging.handlers as handlers
import sys
import os
def init_logger(name:str, filename:str, path:str='./log', level:int=logging.INFO):
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # Check path exist
    if(os.path.exists(path) == False):
        os.makedirs(path)

    file = os.path.join(path,f"{filename}.log")
    formatter = logging.Formatter('%(asctime)s|%(filename)s:%(lineno)d|%(levelname)s|%(message)s')
    formatter.datefmt = '%d-%m-%Y %H:%M:%S'
    # Handler
    consoleHandler = logging.StreamHandler(sys.stdout)
    consoleHandler.setFormatter(formatter)
    # This will rotate log
    fileHandler = handlers.RotatingFileHandler(filename=file, mode='a', maxBytes=10240000, backupCount=10)
    fileHandler.setFormatter(formatter)

    # Add Handler
    logger.addHandler(consoleHandler)
    logger.addHandler(fileHandler)

    logger.propagate = False