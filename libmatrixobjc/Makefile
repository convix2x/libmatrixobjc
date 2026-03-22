TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libmatrixobjc

libmatrixobjc_FILES = libmatrixobjc.m
libmatrixobjc_CFLAGS = -fobjc-arc
libmatrixobjc_INSTALL_PATH = /usr/local/lib

include $(THEOS_MAKE_PATH)/library.mk
