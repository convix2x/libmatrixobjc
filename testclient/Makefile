TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = testclient

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = testclient

testclient_FILES = main.m TeCliAppDelegate.m TeCliRootViewController.m
testclient_FRAMEWORKS = UIKit CoreGraphics
testclient_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
