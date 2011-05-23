SDKVERSION = 4.3
GO_EASY_ON_ME = 1
ADDITIONAL_LDFLAGS = -framework UIKit \
										 -framework CoreFoundation \
										 -framework CoreGraphics \
										 -framework CoreLocation \
										 -framework Preferences \
										 -framework GraphicsServices \
										 -F$(SYSROOT)/System/Library/Frameworks \
										 -F$(SYSROOT)/System/Library/PrivateFrameworks

ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

BUNDLE_NAME = org.unixlife.ios.cydia.lockinfo.powercontrol
org.unixlife.ios.cydia.lockinfo.powercontrol_OBJC_FILES = PowerControlPlugin.mm

include framework/makefiles/common.mk
include framework/makefiles/bundle.mk

endif
