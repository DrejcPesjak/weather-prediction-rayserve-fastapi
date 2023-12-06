import ray
from ray import serve
from fastapi import FastAPI
from google.cloud import storage, bigquery
import numpy as np
import tensorflow as tf

# Constants
BUCKET_NAME = 'europe-central2-rso-ml-airf-05c3abe0-bucket'
MODEL_DIR = 'models'
PROJECT_ID = 'balmy-apogee-404909'
DATASET_ID = 'weather_prediction'
WEATHER_TABLE_ID = 'weather_history_LJ'

# FastAPI app
app = FastAPI()

# Function to get the best model name
def get_best_model_name():
    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = list(bucket.list_blobs(prefix=MODEL_DIR + '/'))

    best_model_file = None
    for blob in blobs:
        if blob.name.endswith('.best'):
            best_model_file = blob.name
            break

    if best_model_file:
        model_name = best_model_file.split('/')[-1].replace('.best', '.h5')
        return model_name
    else:
        raise ValueError("Best model file not found")

def get_data():
    client = bigquery.Client(project=PROJECT_ID)
    query = f"""
        SELECT * 
        FROM `{PROJECT_ID}.{DATASET_ID}.{WEATHER_TABLE_ID}`
        ORDER BY time
        LIMIT 1
    """
    query_job = client.query(query)
    df = query_job.to_dataframe()
    df.set_index('time', inplace=True)
    df = df.astype('float32')
    return df

# Ray Serve deployment
@serve.deployment
@serve.ingress(app)
class ModelPredictor:
    def __init__(self):
        self.model = None
        self.model_name = None
        self.load_model()

    def load_model(self):
        best_model_name = get_best_model_name()
        self.model_name = best_model_name
        model_path = f"gs://{BUCKET_NAME}/{MODEL_DIR}/{best_model_name}"
        self.model = tf.keras.models.load_model(model_path)
    
    @app.get("/")
    async def root(self):
        return f"Hello, we are using model {self.model_name}!"

    @app.get("/predict")
    async def predict(self):
        data = get_data()
        prediction = self.model.predict(data)
        temp_prediction, precip_prediction = prediction
        return {
            'temp_predict': temp_prediction.tolist()[0],
            'precip_predict': precip_prediction.tolist()[0]
        }
    
    # @app.get("/summary")
    # async def summary(self):
    #     stringlist = []
    #     self.model.summary(print_fn=lambda x: stringlist.append(x))
    #     short_model_summary = "\n".join(stringlist)
    #     return short_model_summary
    
    @app.get("/summary")
    async def summary(self):
        stringlist = []
        self.model.summary(print_fn=lambda x: stringlist.append(x))
        return stringlist


model_predictor = ModelPredictor.bind()
