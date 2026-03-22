TARGET := iphone:clang:6.1:6.0
ARCHS := armv7 armv7s

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libmatrixobjc

libmatrixobjc_FILES = \
	MatrixDefines.m \
	MatrixClient.m \
	MatrixRoom.m \
	MatrixMessage.m \
	MatrixUser.m \
	MatrixSyncResponse.m

libmatrixobjc_PUBLIC_HEADERS = \
	MatrixClient.h \
	MatrixRoom.h \
	MatrixMessage.h \
	MatrixUser.h \
	MatrixSyncResponse.h \
	MatrixDefines.h

libmatrixobjc_CFLAGS = -fobjc-arc
libmatrixobjc_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk