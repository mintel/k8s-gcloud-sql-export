FROM google/cloud-sdk:284.0.0-alpine

ARG BUILD_DATE
ARG VCS_REF

RUN echo $BUILD_DATE
RUN echo $VCS_REF

LABEL maintainer="Nick Badger <nbadger@mintel.com>" \
      org.opencontainers.image.title="k8s-gcloud-export" \
      org.opencontainers.image.description="An image for exporting mysql databases using 'gcloud sql export', and pushing them to a Google bucket." \
      org.opencontainers.url="https://github.com/mintel/k8s-gcloud-sql-export" \
      org.opencontainers.source="https://github.com/mintel/k8s-gcloud-sql-export.git" \
      org.opencontainers.image.version="0.1.0-rc1" \
      org.opencontainers.image.vendor="Mintel Group Ltd." \
      org.opencontainers.image.licences="MIT" \
      org.opencontainers.authors="Nick Badger <nbadger@mintel.com>" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF"

WORKDIR /tmp

ENV JQ_VERSION=1.5 \
    JQ_SHA256=c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d

# Install jq
RUN set -e \
    && wget -q https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -O /tmp/jq \
    && chmod +x /tmp/jq \
    && echo "$JQ_SHA256  jq" | sha256sum -c \
    && mv /tmp/jq /usr/local/bin

COPY ./scripts/gcloud-sql-export.sh /usr/local/bin/gcloud-sql-export.sh

RUN chmod +x /usr/local/bin/gcloud-sql-export.sh

ENTRYPOINT ["/usr/local/bin/gcloud-sql-export.sh"]
