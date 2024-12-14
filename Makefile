PACKAGE_VERSION = 1.0.0
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
else
TARGET = iphone:clang:14.5:8.3
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EmoZoom

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
