# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

# Use official OpenCloud image as base
FROM opencloudeu/opencloud:4.0.3 AS upstream

# Build final image based on Alpine
FROM alpine:3.20

RUN apk add --no-cache \
    ca-certificates \
    curl \
    mailcap \
    vips

# Copy OpenCloud binary from upstream image
COPY --from=upstream /usr/bin/opencloud /usr/bin/opencloud

# Create non-root user and data directory
RUN mkdir -p /var/lib/opencloud && \
    addgroup -g 1000 opencloud && \
    adduser -D -u 1000 -G opencloud opencloud && \
    chown -R opencloud:opencloud /var/lib/opencloud

USER opencloud

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/usr/bin/opencloud"]
CMD ["server"]
