# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: AGPL-3.0-or-later

FROM registry-1.docker.io/library/alpine:3.21.3

RUN apk add --no-cache \
    python3=3.12.9-r0 \
    py3-pip=24.3.1-r0 \
    bash=5.2.37-r0 \
    curl=8.12.1-r1 \
  && addgroup -S "app" \
  && adduser -D -G "app" -h "/app" -s "/bin/bash" -u 1000 -S "app"

USER app

WORKDIR /app

COPY ./lib/ /app/lib/
COPY ./config/ /app/config/
COPY ./provision.py /app/
COPY ./deprovision_disable.py /app/
COPY ./deprovision_delete.py /app/
COPY ./deprovision_user.py /app/
COPY ./sync_users.py /app/
COPY ./archive_service_user.py /app/
COPY ./Makefile /app/
COPY ./.env.example /app/.env.example
COPY ./requirements.txt /app/

RUN pip install --no-cache-dir --break-system-packages -r /app/requirements.txt

CMD ["/app/provision.py"]
