FROM rayproject/ray:latest

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the application
COPY rayserve_model.py .

# NOTE: The following is only for development purposes, in production on GCP, the credentials are automatically set
# Copy google credentials
COPY balmy-apogee-404909-3d6e10b65c43.json credentials.json
# Set google environment variables
ENV GOOGLE_APPLICATION_CREDENTIALS=credentials.json

# Expose port 8000
EXPOSE 8000

# Run the application
CMD ["serve", "run", "rayserve_model:model_predictor"]

# # Build the docker image
# docker build -t weather-pred-ray .
# # Run the docker image
# docker run -p 8000:8000 weather-pred-ray
