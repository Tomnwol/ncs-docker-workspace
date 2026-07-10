ARG TOOLCHAIN_IMAGE
FROM ${TOOLCHAIN_IMAGE}

ARG NCS_MANIFEST_REVISION
ENV WORKSPACE_DIR=/workspace
ENV ACCEPT_JLINK_LICENSE=1

SHELL ["/bin/bash", "-c"]

RUN source /opt/non-interactive-setup.sh \
    && git config --global --add safe.directory '*' \
    && west init -m https://github.com/nrfconnect/sdk-nrf \
        --mr "${NCS_MANIFEST_REVISION}" \
        "${WORKSPACE_DIR}" \
    && cd "${WORKSPACE_DIR}" \
    && west update \
    && west zephyr-export

WORKDIR /workspace
