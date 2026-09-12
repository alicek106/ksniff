# ksniff

[![Build Status](https://travis-ci.org/eldadru/ksniff.svg?branch=master)](https://travis-ci.org/eldadru/ksniff)

A kubectl plugin that utilize tcpdump and Wireshark to start a remote capture on any pod in your
 Kubernetes cluster.

You get the full power of Wireshark with minimal impact on your running pods.

### Intro

When working with micro-services, many times it's very helpful to get a capture of the network
activity between your micro-service and it's dependencies.

ksniff use kubectl to upload a statically compiled tcpdump binary to your pod and redirecting it's
output to your local Wireshark for smooth network debugging experience.

### Demo
![Demo!](https://i.imgur.com/hWtF9r2.gif)

### Production Readiness
Ksniff [isn't production ready yet](https://github.com/eldadru/ksniff/issues/96#issuecomment-762454991), running ksniff for production workloads isn't recommended at this point.

## Installation
Installation via krew (https://github.com/GoogleContainerTools/krew)

    kubectl krew install sniff
    
For manual installation, download the latest release package, unzip it and use the attached makefile:  

    unzip ksniff.zip
    make install

### Wireshark

If you are using Wireshark with ksniff you must use at least version 3.4.0. Using older versions may result in issues reading captures (see [Known Issues](#known-issues) below).

## Build

Requirements:
1. libpcap-dev: for tcpdump compilation (Ubuntu: sudo apt-get install libpcap-dev)
2. go 1.11 or newer

Compiling:
 
    linux:      make linux
    windows:    make windows
    mac:        make darwin
 

To compile a static tcpdump binary:

    make static-tcpdump

### Usage

    kubectl < 1.12:
    kubectl plugin sniff <POD_NAME> [-n <NAMESPACE_NAME>] [-c <CONTAINER_NAME>] [-i <INTERFACE_NAME>] [-f <CAPTURE_FILTER>] [-o OUTPUT_FILE] [-l LOCAL_TCPDUMP_FILE] [-r REMOTE_TCPDUMP_FILE]
    
    kubectl >= 1.12:
    kubectl sniff <POD_NAME> [-n <NAMESPACE_NAME>] [-c <CONTAINER_NAME>] [-i <INTERFACE_NAME>] [-f <CAPTURE_FILTER>] [-o OUTPUT_FILE] [-l LOCAL_TCPDUMP_FILE] [-r REMOTE_TCPDUMP_FILE]
    
    POD_NAME: Required. the name of the kubernetes pod to start capture it's traffic.
    NAMESPACE_NAME: Optional. Namespace name. used to specify the target namespace to operate on.
    CONTAINER_NAME: Optional. If omitted, the first container in the pod will be chosen.
    INTERFACE_NAME: Optional. Pod Interface to capture from. If omitted, all Pod interfaces will be captured.
    CAPTURE_FILTER: Optional. specify a specific tcpdump capture filter. If omitted no filter will be used.
    OUTPUT_FILE: Optional. if specified, ksniff will redirect tcpdump output to local file instead of wireshark. Use '-' for stdout.
    LOCAL_TCPDUMP_FILE: Optional. if specified, ksniff will use this path as the local path of the static tcpdump binary.
    REMOTE_TCPDUMP_FILE: Optional. if specified, ksniff will use the specified path as the remote path to upload static tcpdump to.

#### Air gapped environments
Use `--image` and `--tcpdump-image` flags (or KUBECTL_PLUGINS_LOCAL_FLAG_IMAGE and KUBECTL_PLUGINS_LOCAL_FLAG_TCPDUMP_IMAGE environment variables) to override the default container images and use your own e.g (docker):
  
    kubectl plugin sniff <POD_NAME> [-n <NAMESPACE_NAME>] [-c <CONTAINER_NAME>] --image <PRIVATE_REPO>/docker --tcpdump-image <PRIVATE_REPO>/tcpdump
   

#### Non-Privileged and Scratch Pods
To reduce attack surface and have small and lean containers, many production-ready containers runs as non-privileged user
or even as a scratch container.

To support those containers as well, ksniff now ships with the "-p" (privileged) mode.
When executed with the -p flag, ksniff will create a new pod on the remote kubernetes cluster that will have access to the node docker daemon.

ksniff will than use that pod to execute a container attached to the target container network namespace 
and perform the actual network capture.

#### Piping output to stdout
By default ksniff will attempt to start a local instance of the Wireshark GUI. You can integrate with other tools
using the `-o -` flag to pipe packet cap data to stdout.

Example using `tshark`:

    kubectl sniff pod-name -f "port 80" -o - | tshark -r -

### Contribution
More than welcome! please don't hesitate to open bugs, questions, pull requests 

### Future Work
1. Instead of uploading static tcpdump, use the future support of "kubectl debug" feature
 (https://github.com/kubernetes/community/pull/649) which should be a much cleaner solution.
 
### Known Issues

#### Wireshark and TShark cannot read pcap

*Issues [100](https://github.com/eldadru/ksniff/issues/100) and [98](https://github.com/eldadru/ksniff/issues/98)*

Wireshark may show `UNKNOWN` in Protocol column. TShark may report the following in output:

```
tshark: The standard input contains record data that TShark doesn't support.
(pcap: network type 276 unknown or unsupported)
```

This issue happens when using an old version of Wireshark or TShark to read the pcap created by ksniff. Upgrade Wireshark or TShark to resolve this issue. Ubuntu LTS versions may have this problem with stock package versions but using the [Wireshark PPA will help](https://github.com/eldadru/ksniff/issues/100#issuecomment-789503442).

---

## Fork Notes

**Everything below this line was added after forking from the now-unmaintained [eldadru/ksniff](https://github.com/eldadru/ksniff).** The README content above this line is the untouched original upstream text.

### Installing as `kubectl sniff` (no krew needed)

kubectl's plugin mechanism auto-discovers any executable named `kubectl-<verb>` that's on `$PATH` - no krew involved. `make darwin`/`make linux`/`make windows` already produce a correctly-named `kubectl-sniff*` binary, and `make install` copies it onto `$PATH` (see the Makefile's `PLUGIN_FOLDER` logic). Once it's there, `kubectl sniff` just works.

Real krew (`kubectl krew install sniff`) isn't an option for this fork: the plugin name `sniff` is already taken in the official krew-index by upstream `eldadru/ksniff`, so a personal fork can't be published there under the same name. A custom krew index (a second repo just to host a `.krew.yaml` + GitHub Releases) was considered and skipped - unnecessary indirection for a single-machine personal install.

### Docker runtime support removed

Docker/dockershim as a node container runtime is no longer supported - it was removed from Kubernetes itself in 1.24, so there's no cluster left to target with it. `DockerBridge` and its tests were deleted; `NewContainerRuntimeBridge("docker")` no longer exists.

### Building & publishing the privileged-pod images (multi-arch)

`-p`/`--privileged` mode doesn't run the `kubectl-sniff` binary itself on the cluster - it spins up a separate "privileged pod" on the target node and, depending on the node's container runtime, either runs `tcpdump` directly inside it or spawns one more sibling container next to it. Those images used to be x86_64-only, third-party images (`docker.io/hamravesh/ksniff-helper` and `docker.io/maintained/tcpdump`) that this repo never built. `build/tcpdump` and `build/helper` now contain this fork's own Dockerfiles for them, published as multi-arch (amd64+arm64) images to this fork's public ECR (`public.ecr.aws/o5v4y7w2/`) - only relevant to this fork's maintainer, not to upstream ksniff users.

| Runtime | Role | Image | Source |
|---|---|---|---|
| CRI-O | the privileged pod itself | `ksniff-tcpdump` | `build/tcpdump` |
| containerd | the privileged pod itself | `ksniff-helper` | `build/helper` |
| containerd | sibling container spawned via `ctr run` | `ksniff-tcpdump` | `build/tcpdump` |

To rebuild and publish both images locally (no GitHub CI involved):

    # one-time: ECR Public doesn't auto-create repositories on push
    aws ecr-public create-repository --repository-name ksniff-tcpdump --region us-east-1
    aws ecr-public create-repository --repository-name ksniff-helper --region us-east-1

    # one-time: authenticate to ECR Public (the API is always us-east-1, regardless of the alias's actual region)
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

    # one-time: a buildx builder that can actually produce arm64 output
    docker buildx create --use

    make images

`make images` pushes `public.ecr.aws/o5v4y7w2/ksniff-tcpdump:v1` and `public.ecr.aws/o5v4y7w2/ksniff-helper:v1` (see `IMAGE_REGISTRY`/`IMAGE_TAG` in the Makefile). **Bump `IMAGE_TAG` on every rebuild you intend to actually use** - the privileged pod is created with `ImagePullPolicy: IfNotPresent`, so pushing over the same tag can leave any node that already pulled it silently running the old image.

The tag lives in two independent places, so bumping the Makefile's `IMAGE_TAG` alone isn't enough to actually use a new build: `kubectl-sniff` itself only knows about the tag compiled into `DefaultHelperImage`/`DefaultTcpdumpImage` in `pkg/service/sniffer/runtime/runtime.go`. After pushing a new tag, either update those two constants and rebuild `kubectl-sniff`, or skip touching the constants and just set `KSNIFF_HELPER_IMAGE`/`KSNIFF_TCPDUMP_IMAGE` to the new tag in the environment ksniff runs in.

### Overriding the default images without rebuilding

The upstream `--image`/`--tcpdump-image` flags (see "Air gapped environments" above) still override the image for a single invocation. This fork adds one more layer underneath them: set `KSNIFF_HELPER_IMAGE` and/or `KSNIFF_TCPDUMP_IMAGE` in the environment `kubectl-sniff` runs in to change the *compiled-in default* without a flag on every invocation and without rebuilding the binary.

Precedence, highest first:
1. `--image`/`--tcpdump-image` flag (or its `KUBECTL_PLUGINS_LOCAL_FLAG_*` env var)
2. `KSNIFF_HELPER_IMAGE`/`KSNIFF_TCPDUMP_IMAGE`
3. the compiled-in default (`public.ecr.aws/o5v4y7w2/ksniff-helper:v1` / `public.ecr.aws/o5v4y7w2/ksniff-tcpdump:v1`)

### Compatibility notes

- **Pod Security Admission.** The privileged pod ksniff creates runs `privileged: true`, `hostPID: true`, with the node's `/` bind-mounted. On a namespace enforcing the `baseline` or `restricted` Pod Security Standard (the built-in replacement for PodSecurityPolicy, stable since Kubernetes 1.25), pod creation will be rejected. Run `-p`/`--privileged` mode against a namespace labelled (or defaulted to) `enforce: privileged`.
- **`make install` and `kubectl version --short`.** The Makefile detects the installed kubectl's minor version via `kubectl version --client=true --short=true -o yaml`. The `--short` flag was deprecated in kubectl 1.24 and removed entirely in 1.28, so this detection (and `make install`) breaks on any current kubectl. Not fixed as part of this pass; the one-line fix is to drop `--short` and read `clientVersion.minor` from the plain YAML output.
