# libmatrixobjc

Matrix API library for Theos/Objective-C

# Note

You should probably set up a proxy server because most homeservers have stopped supporting the ciphers used in iOS 6

# Examples

You can view an example client in the testclient folder. The library is inside libmatrixobjc folder.
View the wiki for api docs

# Building

The way I reccommend building this into your app is compiling it into the app directly:
```makefile
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
```


# License
`libmatrixobjc` is licensed under the GNU Lesser General Public License v2.1.
The `testclient` is licensed under the GNU General Public License v3.
See `LICENSE` for details.