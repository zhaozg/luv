cmake_minimum_required(VERSION 2.8)

if(POLICY CMP0053)
  cmake_policy(SET CMP0053 NEW) # faster evaluation of variable references
endif()

project(luv C ASM)

set(LUV_VERSION_MAJOR 1)
set(LUV_VERSION_MINOR 32)
set(LUV_VERSION_PATCH 0)
set(LUV_VERSION ${LUV_VERSION_MAJOR}.${LUV_VERSION_MINOR}.${LUV_VERSION_PATCH})

option(BUILD_MODULE "Build as module" ON)
option(BUILD_SHARED_LIBS "Build shared library" OFF)
option(WITH_SHARED_LIBUV
       "Link to a shared libuv library instead of static linking" OFF)

if(MINGW)
  add_definitions(-D_WIN32_WINNT=0x0600)
endif(MINGW)

if(WIN32)
  # replace /MD to /MT to avoid link msvcr*.dll this needs to be before
  # add_subdirectory calls so that they inherit the modified flags
  set(CompilerFlags
      CMAKE_C_FLAGS
      CMAKE_C_FLAGS_DEBUG
      CMAKE_C_FLAGS_MINSIZEREL
      CMAKE_C_FLAGS_RELWITHDEBINFO
      CMAKE_C_FLAGS_RELEASE)
  foreach(CompilerFlag ${CompilerFlags})
    string(REPLACE "/MD"
                   "/MT"
                   ${CompilerFlag}
                   "${${CompilerFlag}}")
  endforeach()
endif()

if(NOT WITH_LUA_ENGINE)
  set(WITH_LUA_ENGINE "LuaJIT" CACHE STRING "Link to LuaJIT or PUC Lua" FORCE)
  set_property(CACHE WITH_LUA_ENGINE PROPERTY STRINGS "Lua;LuaJIT")
endif()

if(NOT LUA_BUILD_TYPE)
  set(LUA_BUILD_TYPE "Static"
      CACHE STRING
            "Build Lua/LuaJIT as static, dynamic libary, or use system one"
      FORCE)
  set_property(CACHE LUA_BUILD_TYPE PROPERTY STRINGS "Static;Dynamic;System")
endif()

if(WITH_LUA_ENGINE STREQUAL Lua)
  if(NOT WIN32)
    add_definitions(-DLUA_USE_DLOPEN)
  endif()
  set(USE_LUAJIT OFF)
else()
  set(USE_LUAJIT ON)
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

if(WITH_SHARED_LIBUV)
  find_package(Libuv REQUIRED)
  include_directories(${LIBUV_INCLUDE_DIR})
else()
  if(DEFINED ENV{LIBUV_DIR})
    set(LIBUV_DIR $ENV{LIBUV_DIR})
  else()
    set(LIBUV_DIR deps/libuv)
  endif()
  include_directories(${LIBUV_DIR}/include)
  add_subdirectory(${LIBUV_DIR} libuv EXCLUDE_FROM_ALL)
  if(BUILD_MODULE)
    add_definitions(-DBUILDING_UV_SHARED)
  endif()
  set(LIBUV_LIBRARIES uv_a)
  set_target_properties(uv_a PROPERTIES COMPILE_FLAGS "-fPIC")
endif()

if(LUA)
  message(STATUS "Lua: using information from luarocks")

  message(STATUS "LUA_LIBDIR: " ${LUA_LIBDIR})
  message(STATUS "LUA_INCDIR: " ${LUA_INCDIR})
  message(STATUS "LUA: " ${LUA})

  set(LUA_EXECUTABLE "${LUA}")
  set(LUA_INCLUDE_DIR "${LUA_INCDIR}")
  set(LUA_PACKAGE_PATH "${LUADIR}")
  set(LUA_PACKAGE_CPATH "${LIBDIR}")

  set(INSTALL_LIB_DIR ${LIBDIR})

  get_filename_component(LUA_EXEC_NAME ${LUA_EXECUTABLE} NAME_WE)
  if(LUA_EXEC_NAME STREQUAL "luajit")
    find_library(LUA_LIBRARIES
                 NAMES luajit libluajit
                 PATHS ${LUA_LIBDIR}
                 NO_DEFAULT_PATH)
  elseif(LUA_EXEC_NAME MATCHES "lua.*")
    find_library(LUA_LIBRARIES
                 NAMES lua
                       lua53
                       lua52
                       lua51
                       liblua
                       liblua53
                       liblua52
                       liblua51
                 PATHS ${LUA_LIBDIR}
                 NO_DEFAULT_PATH)
  endif()
  message(STATUS "Lua library: ${LUA_LIBRARIES}")

  include_directories(${LUA_INCLUDE_DIR})
else()
  if(LUA_BUILD_TYPE STREQUAL System)
    if(USE_LUAJIT)
      find_package(LuaJIT REQUIRED)
      include_directories(${LUAJIT_INCLUDE_DIR})
      link_directories(${LUAJIT_LIBRARIES})
    else()
      find_package(Lua REQUIRED)
      include_directories(${LUA_INCLUDE_DIR})
    endif()
  else()
    if(LUA_BUILD_TYPE STREQUAL Static)
      set(WITH_SHARED_LUA OFF)
    else()
      set(WITH_SHARED_LUA ON)
    endif()
    if(DEFINED ENV{LUA_FORGE_DIR})
      set(LUA_FORGE_DIR $ENV{LUA_FORGE_DIR})
    endif()
    if(NOT LUA_FORGE_DIR)
      message(FATAL_ERROR "Please set LUA_FORGE_DIR")
    endif()

    add_subdirectory(${LUA_FORGE_DIR} lua EXCLUDE_FROM_ALL)
    if(USE_LUAJIT)
      include_directories(${LUA_FORGE_DIR}/LuaJIT/src)
      set(LUA_TARGET luajit PARENT_SCOPE)
      set(LUA_LIBRARIES libluajit PARENT_SCOPE)
      set(LUA_INCLUDE_DIR ${LUA_FORGE_DIR}/LuaJIT/src PARENT_SCOPE)
      set(LUA_TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/lua PARENT_SCOPE)
    else()
      include_directories(${LUA_FORGE_DIR}/lua)
      set(LUA_TARGET lua PARENT_SCOPE)
      set(LUA_LIBRARIES liblua PARENT_SCOPE)
      set(LUA_INCLUDE_DIR ${LUA_FORGE_DIR}/lua PARENT_SCOPE)
      set(LUA_TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/lua PARENT_SCOPE)
    endif()
  endif()
endif()

if(BUILD_MODULE)
  add_library(luv MODULE src/luv.c)
  set_target_properties(luv PROPERTIES PREFIX "")
  if(NOT LUA_BUILD_TYPE STREQUAL System)
    message("LUA_TARGET ${LUA_TARGET}")
    add_dependencies(luv ${LUA_TARGET})
  endif()
else()
  add_library(luv src/luv.c)
  if(BUILD_SHARED_LIBS)
    set_target_properties(luv PROPERTIES
      VERSION ${LUV_VERSION} SOVERSION ${LUV_VERSION_MAJOR})
  endif()
endif()

if(APPLE)
  set(
    CMAKE_SHARED_MODULE_CREATE_C_FLAGS
    "${CMAKE_SHARED_MODULE_CREATE_C_FLAGS} -flat_namespace -undefined suppress")
endif()

if(NOT LUA_COMPAT53_DIR)
  set(LUA_COMPAT53_DIR deps/lua-compat-5.3/c-api)
endif()
if(DEFINED ENV{LUA_COMPAT53_DIR})
  set(LUA_COMPAT53_DIR $ENV{LUA_COMPAT53_DIR})
endif()
include_directories(${LUA_COMPAT53_DIR})

if(WIN32)
  add_definitions(-DLUA_BUILD_AS_DLL -DLUA_LIB)
  target_link_libraries(luv ${LIBUV_LIBRARIES} ${LUA_LIBRARIES})
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
  target_link_libraries(luv ${LIBUV_LIBRARIES} rt)
else()
  target_link_libraries(luv ${LIBUV_LIBRARIES})
endif()

if(NOT LUA)
  if(BUILD_MODULE)
    if(WIN32)
      set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")
    else()
      set(
        INSTALL_LIB_DIR
        "${CMAKE_INSTALL_PREFIX}/lib/lua/${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}"
        )
    endif()
  else()
    set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib"
        CACHE PATH "Installation directory for libraries")
    set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include/luv"
        CACHE PATH "Installation directory for headers")
  endif()
endif()

if(CMAKE_INSTALL_PREFIX)
  install(TARGETS luv
          ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
          LIBRARY DESTINATION "${INSTALL_LIB_DIR}")
  if(NOT BUILD_MODULE)
    if(UNIX)
      set(prefix ${CMAKE_INSTALL_PREFIX})
      set(includedir ${INSTALL_INC_DIR})
      set(libdir ${INSTALL_LIB_DIR})
      configure_file(libluv.pc.in ${CMAKE_CURRENT_BINARY_DIR}/libluv.pc @ONLY)
      install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libluv.pc
              DESTINATION ${INSTALL_LIB_DIR}/pkgconfig)
    endif()
    install(FILES src/luv.h
                  src/util.h
                  src/lhandle.h
                  src/lreq.h
            DESTINATION "${INSTALL_INC_DIR}")
  endif()
endif()
