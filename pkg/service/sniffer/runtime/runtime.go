package runtime

import (
	"fmt"
	"os"
)

var SupportedContainerRuntimes = []string{
	"cri-o",
	"containerd",
}

// DefaultHelperImage and DefaultTcpdumpImage are the images ksniff pulls onto the
// privileged pod when the user doesn't override them via --image/--tcpdump-image.
// Built from build/helper and build/tcpdump and published to the user's own
// registry (see README "Building & publishing the privileged-pod images").
const (
	DefaultHelperImage  = "public.ecr.aws/o5v4y7w2/ksniff-helper:v1"
	DefaultTcpdumpImage = "public.ecr.aws/o5v4y7w2/ksniff-tcpdump:v1"

	EnvHelperImage  = "KSNIFF_HELPER_IMAGE"
	EnvTcpdumpImage = "KSNIFF_TCPDUMP_IMAGE"
)

// imageFromEnv lets the compiled-in default image be swapped at runtime (e.g. to
// pin a different tag) without rebuilding the ksniff binary.
func imageFromEnv(envKey string, defaultValue string) string {
	if v := os.Getenv(envKey); v != "" {
		return v
	}
	return defaultValue
}

type ContainerRuntimeBridge interface {
	NeedsPid() bool
	BuildInspectCommand(containerId string) []string
	ExtractPid(inspection string) (*string, error)
	BuildTcpdumpCommand(containerId *string, netInterface string, filter string, pid *string, socketPath string, tcpdumpImage string) []string
	BuildCleanupCommand() []string
	GetDefaultImage() string
	GetDefaultTCPImage() string
	GetDefaultSocketPath() string
}

func NewContainerRuntimeBridge(runtimeName string) ContainerRuntimeBridge {
	switch runtimeName {
	case "cri-o":
		return NewCrioBridge()
	case "containerd":
		return NewContainerdBridge()
	default:
		panic(fmt.Sprintf("Unable to build bridge to %s", runtimeName))
	}
}
