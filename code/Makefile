CXX := g++
VERSION := $(shell cat VERSION 2>/dev/null || echo 0.0.0)

# Lightweight profile is the default. Enable WITH_VIPS=1 only when the
# optional high-format-count image backend is wanted.
WITH_VIPS ?= 0
PKGS := raylib libarchive libmagic openssl
ifeq ($(WITH_VIPS),1)
PKGS += vips
CPPFLAGS += -DRAYMOTHFM_WITH_VIPS=1
endif

PKG_CFLAGS := $(shell pkg-config --cflags $(PKGS) 2>/dev/null)
PKG_LIBS := $(shell pkg-config --libs libarchive libmagic openssl 2>/dev/null)
RAYLIB_LIBS := $(shell pkg-config --static --libs raylib 2>/dev/null)
ifeq ($(WITH_VIPS),1)
PKG_LIBS += $(shell pkg-config --libs vips 2>/dev/null)
endif
CPPFLAGS += $(PKG_CFLAGS) -DRAYMOTHFM_VERSION=\"$(VERSION)\"
CXXFLAGS := -std=c++20 -O2 -flto -Wall -Wextra -Wpedantic
LDFLAGS := -flto -s -Wl,--as-needed
LDLIBS := $(RAYLIB_LIBS) $(PKG_LIBS) -lm -lpthread -ldl -lrt -lX11

TARGET := raymothfm
DEBUG_TARGET := raymothfm-debug
SOURCES := main.cpp
OBJECTS := $(SOURCES:.cpp=.o)
DEBUG_OBJECTS := main.debug.o

all: $(TARGET)

check-deps:
	@pkg-config --exists $(PKGS) || { echo "Missing pkg-config dependencies: $(PKGS)"; exit 1; }

$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

%.o: %.cpp rayicons.h VERSION | check-deps
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Debug build: no stripping/LTO, full symbols, frame pointers, ASan + UBSan.
debug: CXXFLAGS := -std=c++20 -O0 -g3 -fno-omit-frame-pointer -Wall -Wextra -Wpedantic -fsanitize=address,undefined

debug: LDFLAGS := -fsanitize=address,undefined

debug: $(DEBUG_TARGET)

$(DEBUG_TARGET): $(DEBUG_OBJECTS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(DEBUG_OBJECTS) -o $@ $(LDLIBS)

main.debug.o: main.cpp rayicons.h VERSION | check-deps
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

run-debug: $(DEBUG_TARGET)
	ASAN_OPTIONS=detect_leaks=1:abort_on_error=1 ./$(DEBUG_TARGET)

version:
	@echo raymothfm $(VERSION)

mkcfg: $(TARGET)
	./$(TARGET) --mkcfg

strip: $(TARGET)
	strip -s $(TARGET)

PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
DOC_DIR ?= $(DATADIR)/doc/raymothfm
DESKTOP_FILE := ../distro/debian/raymothfm.desktop
UPSTREAM_LICENSE := ../LICENSE
RAYLIB_LICENSE := ../distro/debian/licenses/RAYLIB-5.5.txt
GLFW_LICENSE := ../distro/debian/licenses/GLFW.txt
NOTICE_FILE := ../distro/debian/NOTICE

install: $(TARGET)
	install -Dm755 $(TARGET) $(DESTDIR)$(BINDIR)/raymothfm
	install -Dm644 $(DESKTOP_FILE) $(DESTDIR)$(DATADIR)/applications/raymothfm.desktop
	install -Dm644 $(UPSTREAM_LICENSE) $(DESTDIR)$(DOC_DIR)/copyright
	install -Dm644 $(RAYLIB_LICENSE) $(DESTDIR)$(DOC_DIR)/RAYLIB-5.5.txt
	install -Dm644 $(GLFW_LICENSE) $(DESTDIR)$(DOC_DIR)/GLFW.txt
	install -Dm644 $(NOTICE_FILE) $(DESTDIR)$(DOC_DIR)/NOTICE

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/raymothfm
	rm -f $(DESTDIR)$(DATADIR)/applications/raymothfm.desktop
	rm -rf $(DESTDIR)$(DOC_DIR)

clean:
	rm -f $(TARGET) $(DEBUG_TARGET) $(OBJECTS) $(DEBUG_OBJECTS)

.PHONY: all check-deps debug run run-debug version mkcfg strip install uninstall clean
