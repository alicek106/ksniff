# ksniff-helper: the containerd privileged-pod image (GetDefaultImage in
# containerd.go). ksniff execs a shell script inside this pod that runs
# `crictl pull`/`crictl inspect` directly (needs crictl+jq in this image) and
# then `chroot /host ctr run ...` (uses the HOST's own ctr binary, not this
# image's - chroot happens before ctr is invoked).
FROM alpine:3.20

ARG TARGETARCH
ARG CRICTL_VERSION=v1.31.1

RUN apk add --no-cache jq curl \
    && curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${TARGETARCH}.tar.gz" \
       | tar -C /usr/local/bin -xz \
    && apk del curl

ENTRYPOINT ["/bin/sh"]
