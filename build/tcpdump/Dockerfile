# ksniff-tcpdump: the "tcpdump runner" image.
#
# Used two ways depending on the target node's container runtime:
#   - CRI-O:       this image IS the privileged pod itself (GetDefaultImage) -
#                  tcpdump runs inside it directly via `nsenter`.
#   - containerd:  spawned as a sibling container on the host via
#                  `chroot /host ctr run` (GetDefaultTCPImage).
#
# ENTRYPOINT must be tcpdump itself: callers invoke it as
#   ctr run <image> -i <iface> -U -w - <filter>
# i.e. bare arguments, no shell wrapper.
FROM alpine:3.20

RUN apk add --no-cache tcpdump util-linux

ENTRYPOINT ["tcpdump"]
