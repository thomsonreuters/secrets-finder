FROM python@sha256:320a7a4250aba4249f458872adecf92eea88dc6abd2d76dc5c0f01cac9b53990

RUN pip install poetry==1.8.3 --no-cache-dir

WORKDIR /app

COPY . /app/

RUN poetry self add poetry-plugin-lambda-build \
    && poetry self add poetry-plugin-export \
    && poetry lock --no-update \
    && poetry build-lambda
