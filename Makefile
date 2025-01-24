LUV_TAG=$(shell git describe --tags)

ifdef WITHOUT_AMALG
	CMAKE_OPTIONS+= -DWITH_AMALG=OFF
endif

BUILD_MODULE ?= ON
BUILD_SHARED_LIBS ?= OFF
BUILD_STATIC_LIBS ?= OFF
WITH_SHARED_LIBUV ?= OFF
WITH_LUA_ENGINE ?= LuaJIT
LUA_BUILD_TYPE ?= Static
BUILD_DIR ?= build
# options: Release, Debug, RelWithDebInfo, MinSizeRel
BUILD_TYPE ?= RelWithDebInfo

ifeq ($(WITH_LUA_ENGINE), LuaJIT)
  LUABIN=build/lua/luajit
else
  LUABIN=build/lua/lua
endif

CMAKE_OPTIONS += \
	-DBUILD_MODULE=$(BUILD_MODULE) \
	-DBUILD_SHARED_LIBS=$(BUILD_SHARED_LIBS) \
	-DBUILD_STATIC_LIBS=$(BUILD_STATIC_LIBS) \
	-DWITH_SHARED_LIBUV=$(WITH_SHARED_LIBUV) \
	-DWITH_LUA_ENGINE=$(WITH_LUA_ENGINE) \
	-DLUA_BUILD_TYPE=$(LUA_BUILD_TYPE) \
	-DCMAKE_BUILD_TYPE=$(BUILD_TYPE)

ifdef INSTALL_PREFIX
CMAKE_OPTIONS += -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX)
endif

ifeq ($(MAKE),mingw32-make)
CMAKE_OPTIONS += -G"MinGW Makefiles"
LUV_EXT ?= .dll
LUV_CP  ?= cp -f
endif

LUV_EXT ?= .so
LUV_CP  ?= ln -sf

all: luv

deps/libuv/include:
	git submodule update --init deps/libuv

deps/lua-forge/cmake:
	git submodule update --init deps/lua-forge

$(BUILD_DIR)/Makefile: deps/libuv/include deps/lua-forge/cmake
	cmake -H. -B$(BUILD_DIR) ${CMAKE_OPTIONS}

luv: $(BUILD_DIR)/Makefile
	cmake --build $(BUILD_DIR)
	$(LUV_CP) $(BUILD_DIR)/luv$(LUV_EXT) luv$(LUV_EXT)

install: luv
	$(MAKE) -C $(BUILD_DIR) install

clean:
	rm -rf $(BUILD_DIR) luv$(LUV_EXT)

test: luv
	${LUABIN} tests/run.lua
	$(MAKE) -C $(BUILD_DIR) test
	$(BUILD_DIR)/test tests/manual-test-external-loop.lua

reset:
	git submodule update --init --recursive && \
	  git clean -f -d && \
	  git checkout .

publish-luarocks:
	github-release upload --user luvit --repo luv --tag ${LUV_TAG} \
	  --file luv-${LUV_TAG}.tar.gz --name luv-${LUV_TAG}.tar.gz
	luarocks upload luv-${LUV_TAG}.rockspec --api-key=${LUAROCKS_TOKEN}

# vim: ts=8 sw=8 noet tw=79 fen fdm=marker
