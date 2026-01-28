# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/go/rclone \
      BUILD_SRC=rclone/rclone.git

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:localhealth AS distroless-localhealth

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ENTRYPOINT
  FROM 11notes/go:1.25 AS entrypoint
  COPY ./build /

  RUN set -ex; \
    cd /go/entrypoint; \
    eleven go build /entrypoint main.go; \
    eleven distroless /entrypoint;


# :: RCLONE
  FROM 11notes/go:1.25 AS build
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_SRC \
      BUILD_BIN=/rclone

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    go build -ldflags="-extldflags=-static -s -X github.com/rclone/rclone/fs.Version=${APP_VERSION}" -o /rclone rclone.go; \
    eleven distroless ${BUILD_BIN};

# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/etc; \
    mkdir -p /distroless${APP_ROOT}/mnt; \
    mkdir -p /distroless${APP_ROOT}/cache;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM 11notes/alpine:stable

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
      APP_NAME=${APP_NAME} \
      APP_VERSION=${APP_VERSION} \
      APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=entrypoint /distroless/ /
    COPY --from=build /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: SETUP
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      fuse3; \
    echo "user_allow_other" > /etc/fuse.conf;

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:5572/metrics"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint"]