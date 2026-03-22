TARGET := iphone:clang:6.1
ARCHS := armv7
INSTALL_TARGET_PROCESSES = testclient

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = testclient

testclient_FILES = main.m TeCliAppDelegate.m TeCliRootViewController.m TeCliRoomListViewController.m TeCliChatViewController.m \
	../libmatrixobjc/MatrixDefines.m \
	../libmatrixobjc/MatrixClient.m \
	../libmatrixobjc/MatrixRoom.m \
	../libmatrixobjc/MatrixMessage.m \
	../libmatrixobjc/MatrixUser.m \
	../libmatrixobjc/MatrixSyncResponse.m

testclient_FRAMEWORKS = UIKit CoreGraphics
testclient_CFLAGS = -fobjc-arc -I../libmatrixobjc

include $(THEOS_MAKE_PATH)/application.mk