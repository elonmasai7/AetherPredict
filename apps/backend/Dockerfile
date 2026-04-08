FROM python:3.11-slim

WORKDIR /app
COPY apps/backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY apps/backend/app ./app
COPY apps/flutter_app/build/web ./flutter_app/build/web
COPY apps/flutter_app/build/web/favicon.png ./flutter_app/build/web/favicon.ico
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
