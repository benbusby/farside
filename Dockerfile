# https://cloud.google.com/community/tutorials/elixir-phoenix-on-kubernetes-google-container-engine
# Build time container
ARG ALPINE_VERSION=3.15

FROM elixir:1.13.3-alpine AS builder

ARG app_name=farside
ARG subdir=.
ARG build_env=prod
ARG SOURCE_VERSION
ARG COMMIT=${SOURCE_VERSION}
ARG MIX_ENV=prod

ENV APP_NAME=${app_name} \
    MIX_ENV=${MIX_ENV} \
    COMMIT=${COMMIT}

ENV REPLACE_OS_VARS=true
ENV MIX_ENV=${build_env} TERM=xterm

RUN set -ex && \
    apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    git \
    curl \
    nodejs \
    npm \
    python3 \
    build-base && \
    mix local.rebar --force && \
    mix local.hex --force && \
    mkdir -p /opt/built

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix do deps.get, compile
RUN cd ${subdir}/assets \
  && npm install \
  && npm run deploy \
  && cd .. \
RUN mix release ${app_name} \
  && mv _build/${build_env}/rel/${app_name} /opt/release \
  && mv /opt/release/bin/${app_name} /opt/release/bin/server

# Runtime container
FROM alpine:${ALPINE_VERSION}est

RUN set -ex && \
    apk update && \
    apk add --no-cache \
    bash \
    curl \
    gcc \
    nodejs-current \
    libstdc++ \
    openssl-dev && \
    curl https://raw.githubusercontent.com/eficode/wait-for/f71f8199a0dd95953752fb5d3f76f79ced16d47d/wait-for -o /usr/local/bin/wait-for && \
    chmod +x /usr/local/bin/wait-for

# For local dev, heroku will ignore this
EXPOSE $PORT

WORKDIR /opt/app
COPY --from=0 /opt/release .
RUN addgroup -S elixir && adduser -H -D -S -G elixir elixir
RUN chown -R elixir:elixir /opt/app
USER elixir

# Heroku sets magical $PORT variable
CMD PORT=$PORT
