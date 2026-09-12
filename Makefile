TCPDUMP_VERSION=4.9.2
STATIC_TCPDUMP_NAME=static-tcpdump
NEW_PLUGIN_SYSTEM_MINIMUM_KUBECTL_VERSION=12
IMAGE_REGISTRY=public.ecr.aws/o5v4y7w2
IMAGE_TAG=v1
UNAME := $(shell uname)
ARCH_NAME := $(shell uname -m)
KUBECTL_MINOR_VERSION=$(shell kubectl version --client=true --short=true -o yaml | grep minor | grep -Eow "[0-9]+")
IS_NEW_PLUGIN_SUBSYSTEM := $(shell [ $(KUBECTL_MINOR_VERSION) -ge $(NEW_PLUGIN_SYSTEM_MINIMUM_KUBECTL_VERSION) ] && echo true)

ifeq ($(IS_NEW_PLUGIN_SUBSYSTEM),true)
PLUGIN_FOLDER=/usr/local/bin
else
PLUGIN_FOLDER=~/.kube/plugins/sniff
endif

ifeq ($(UNAME), Darwin)
ifeq ($(ARCH_NAME), arm64)
PLUGIN_NAME=kubectl-sniff-darwin-arm64
else
PLUGIN_NAME=kubectl-sniff-darwin
endif
endif

ifeq ($(UNAME), Linux)
PLUGIN_NAME=kubectl-sniff
endif

linux:
	GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o kubectl-sniff cmd/kubectl-sniff.go

windows:
	GO111MODULE=on GOOS=windows GOARCH=amd64 go build -o kubectl-sniff-windows cmd/kubectl-sniff.go

darwin:
	GO111MODULE=on GOOS=darwin GOARCH=amd64 go build -o kubectl-sniff-darwin cmd/kubectl-sniff.go
	GO111MODULE=on GOOS=darwin GOARCH=arm64 go build -o kubectl-sniff-darwin-arm64 cmd/kubectl-sniff.go

all: linux windows darwin

test:
	GO111MODULE=on go test ./...

static-tcpdump:
	wget http://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz
	tar -xvf tcpdump-${TCPDUMP_VERSION}.tar.gz
	cd tcpdump-${TCPDUMP_VERSION} && CFLAGS=-static ./configure --without-crypto && make
	mv tcpdump-${TCPDUMP_VERSION}/tcpdump ./${STATIC_TCPDUMP_NAME}
	rm -rf tcpdump-${TCPDUMP_VERSION} tcpdump-${TCPDUMP_VERSION}.tar.gz

package:
	zip ksniff.zip kubectl-sniff kubectl-sniff-windows kubectl-sniff-darwin kubectl-sniff-darwin-arm64 static-tcpdump Makefile plugin.yaml LICENSE

install:
	mkdir -p ${PLUGIN_FOLDER}
	cp ${PLUGIN_NAME} ${PLUGIN_FOLDER}/kubectl-sniff
	cp plugin.yaml ${PLUGIN_FOLDER}
	cp ${STATIC_TCPDUMP_NAME} ${PLUGIN_FOLDER}

uninstall:
	rm -f ${PLUGIN_FOLDER}/kubectl-sniff
	rm -f ${PLUGIN_FOLDER}/plugin.yaml
	rm -f ${PLUGIN_FOLDER}/${STATIC_TCPDUMP_NAME}

verify_version:
	./scripts/verify_version.sh

# Builds and pushes the privileged-pod helper images (multi-arch: amd64+arm64)
# to the user's own public ECR. Requires `docker buildx create --use` once,
# and `aws ecr-public get-login-password ... | docker login` beforehand.
# Bump IMAGE_TAG on every rebuild - the privileged pod uses ImagePullPolicy:
# IfNotPresent, so reusing a tag can silently keep serving a stale cached image.
images: images-tcpdump images-helper

images-tcpdump:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_REGISTRY)/ksniff-tcpdump:$(IMAGE_TAG) --push build/tcpdump

images-helper:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_REGISTRY)/ksniff-helper:$(IMAGE_TAG) --push build/helper

clean:
	rm -f kubectl-sniff
	rm -f kubectl-sniff-windows
	rm -f kubectl-sniff-darwin
	rm -f kubectl-sniff-darwin-arm64
	rm -f static-tcpdump
	rm -f ksniff.zip

