package runtime

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewContainerRuntimeBridge_Crio(t *testing.T) {
	bridge := NewContainerRuntimeBridge("cri-o")
	assert.IsType(t, &CrioBridge{}, bridge)
}

func TestNewContainerRuntimeBridge_Invalid(t *testing.T) {
	assert.Panics(t, func() { NewContainerRuntimeBridge("i-do-not-exist") })
}

func TestImageFromEnv_UsesDefaultWhenUnset(t *testing.T) {
	t.Setenv("KSNIFF_TEST_IMAGE_VAR", "")
	assert.Equal(t, "default-value", imageFromEnv("KSNIFF_TEST_IMAGE_VAR", "default-value"))
}

func TestImageFromEnv_UsesEnvWhenSet(t *testing.T) {
	t.Setenv("KSNIFF_TEST_IMAGE_VAR", "overridden-value")
	assert.Equal(t, "overridden-value", imageFromEnv("KSNIFF_TEST_IMAGE_VAR", "default-value"))
}

func TestCrioBridge_GetDefaultImage_UsesEnvOverride(t *testing.T) {
	t.Setenv(EnvTcpdumpImage, "example.com/custom-tcpdump:tag")

	bridge := NewCrioBridge()
	assert.Equal(t, "example.com/custom-tcpdump:tag", bridge.GetDefaultImage())
}

func TestContainerdBridge_GetDefaultImages_UseEnvOverride(t *testing.T) {
	t.Setenv(EnvHelperImage, "example.com/custom-helper:tag")
	t.Setenv(EnvTcpdumpImage, "example.com/custom-tcpdump:tag")

	bridge := NewContainerdBridge()
	assert.Equal(t, "example.com/custom-helper:tag", bridge.GetDefaultImage())
	assert.Equal(t, "example.com/custom-tcpdump:tag", bridge.GetDefaultTCPImage())
}

func TestContainerdBridge_GetDefaultImages_FallBackToDefaults(t *testing.T) {
	t.Setenv(EnvHelperImage, "")
	t.Setenv(EnvTcpdumpImage, "")

	bridge := NewContainerdBridge()
	assert.Equal(t, DefaultHelperImage, bridge.GetDefaultImage())
	assert.Equal(t, DefaultTcpdumpImage, bridge.GetDefaultTCPImage())
}
