# node layer to build static assets
FROM node:22 AS nodejs
WORKDIR /usr/src/app/
COPY package.json yarn.lock ./
RUN yarn install
COPY OpenOversight/app/static/ OpenOversight/app/static/
RUN yarn build


FROM python:3.12.4-slim as base
ARG IS_PROD
ENV DEBIAN_FRONTEND noninteractive
ENV PIP_NO_CACHE_DIR=1
ENV POETRY_NO_INTERACTION=1
ENV POETRY_VIRTUALENVS_CREATE=0
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /usr/src/app

# Install packages depending on ENV arg from docker-compose
ARG BASE_PACKAGES="gcc libpq-dev libjpeg62-turbo-dev libsqlite3-0 zlib1g-dev"
ARG DEV_PACKAGES="firefox-esr"
RUN if [ "$IS_PROD" = "true" ]; then \
        PACKAGES_TO_INSTALL="$BASE_PACKAGES"; \
    else \
        PACKAGES_TO_INSTALL="$BASE_PACKAGES $DEV_PACKAGES"; \
    fi && \
    apt-get update && \
    apt-get install -y -qq --no-install-recommends $PACKAGES_TO_INSTALL && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add runtime dependencies to base image
RUN pip3 install poetry~=1.8.0
COPY pyproject.toml poetry.lock ./
RUN if [ "$IS_PROD" = "true" ]; then \
        poetry install --only main --no-root; \
    else \
        poetry install --no-root; \
    fi

# Setup application
COPY create_db.py .
COPY OpenOversight OpenOversight
COPY --from=nodejs /usr/src/app/OpenOversight/app/static/dist/ OpenOversight/app/static/dist/

CMD if [ "$IS_PROD" = "true" ]; then \
        gunicorn -w 4 -b 0.0.0.0:3000 OpenOversight.app:app; \
    else \
        flask run --host=0.0.0.0 --port=3000; \
    fi
