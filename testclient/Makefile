TARGET := iphone:clang:6.1:6.0
ARCHS := armv7 armv7s
INSTALL_TARGET_PROCESSES = testclient

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = testclient

testclient_FILES = main.m TeCliAppDelegate.m TeCliRootViewController.m
testclient_FRAMEWORKS = UIKit CoreGraphics
testclient_LIBRARIES = matrixobjc
testclient_CFLAGS = -fobjc-arc -I../libmatrixobjc

include $(THEOS_MAKE_PATH)/application.mk