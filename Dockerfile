ARG BASE_BUILDER=hexpm/elixir:1.16.3-erlang-26.2.2-alpine-3.19.1
ARG BASE_RUNNER=alpine:3.19

FROM ${BASE_BUILDER} AS builder

ENV MIX_ENV=prod

RUN apk add git

RUN mix do local.hex --force, local.rebar --force

WORKDIR /app

COPY mix.exs mix.lock /app/

RUN mix deps.get

COPY config/ /app/config/

RUN mix deps.compile

COPY lib/ /app/lib/

COPY priv/ /app/priv/

RUN mix sentry.package_source_code
RUN mix release resource_kit_cli

FROM ${BASE_RUNNER}

ENV LANG=C.UTF-8

ENV MIX_ENV=prod

ENV REPLACE_OS_VARS=true

RUN apk add --no-cache openssl-dev ncurses-libs libgcc libstdc++

WORKDIR /app

ARG APP_VERSION
ARG APP_REVISION

ENV APP_NAME=resource_kit_cli
ENV APP_VERSION=${APP_VERSION}
ENV APP_REVISION=${APP_REVISION}

COPY --from=builder /app/_build/${MIX_ENV}/rel/${APP_NAME} .

CMD ["/app/bin/${APP_NAME}", "start"]
