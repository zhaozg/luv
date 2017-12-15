## Modifications
## Copyright 2014 The Luvit Authors. All Rights Reserved.

## Original Copyright
# Copyright (c) 2014 David Capello
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#project(libuv C)

include(CheckTypeSize)

cmake_minimum_required(VERSION 2.8.9)

IF(DEFINED ENV{LIBUV_DIR})
  SET(LIBUV_DIR $ENV{LIBUV_DIR})
  MESSAGE(STATUS "ENV LIBUV_DIR is $ENV{LIBUV_DIR}")
ELSE()
  set(LIBUV_DIR ${CMAKE_CURRENT_LIST_DIR}/libuv)
ENDIF()
MESSAGE(STATUS "LIBUV_DIR is ${LIBUV_DIR}")

IF(CMAKE_VERSION VERSION_GREATER 3)
  cmake_policy(SET CMP0054 OLD)
ENDIF()

include_directories(
  ${LIBUV_DIR}/src
  ${LIBUV_DIR}/include
)

set(SOURCES
  ${LIBUV_DIR}/include/uv.h
  ${LIBUV_DIR}/include/tree.h
  ${LIBUV_DIR}/include/uv-errno.h
  ${LIBUV_DIR}/include/uv-threadpool.h
  ${LIBUV_DIR}/include/uv-version.h
  ${LIBUV_DIR}/src/fs-poll.c
  ${LIBUV_DIR}/src/heap-inl.h
  ${LIBUV_DIR}/src/inet.c
  ${LIBUV_DIR}/src/queue.h
  ${LIBUV_DIR}/src/threadpool.c
  ${LIBUV_DIR}/src/uv-common.c
  ${LIBUV_DIR}/src/uv-common.h
  ${LIBUV_DIR}/src/version.c
)

if(WIN32 OR MINGW)
  add_definitions(
    -D_WIN32_WINNT=0x0600
    -D_CRT_SECURE_NO_WARNINGS
    -D_GNU_SOURCE
  )
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/include/uv-win.h
    ${LIBUV_DIR}/src/win/async.c
    ${LIBUV_DIR}/src/win/atomicops-inl.h
    ${LIBUV_DIR}/src/win/core.c
    ${LIBUV_DIR}/src/win/detect-wakeup.c
    ${LIBUV_DIR}/src/win/device.c
    ${LIBUV_DIR}/src/win/dl.c
    ${LIBUV_DIR}/src/win/error.c
    ${LIBUV_DIR}/src/win/fs-event.c
    ${LIBUV_DIR}/src/win/fs.c
    ${LIBUV_DIR}/src/win/getaddrinfo.c
    ${LIBUV_DIR}/src/win/getnameinfo.c
    ${LIBUV_DIR}/src/win/handle-inl.h
    ${LIBUV_DIR}/src/win/handle.c
    ${LIBUV_DIR}/src/win/internal.h
    ${LIBUV_DIR}/src/win/loop-watcher.c
    ${LIBUV_DIR}/src/win/pipe.c
    ${LIBUV_DIR}/src/win/poll.c
    ${LIBUV_DIR}/src/win/process-stdio.c
    ${LIBUV_DIR}/src/win/process.c
    ${LIBUV_DIR}/src/win/req-inl.h
    ${LIBUV_DIR}/src/win/req.c
    ${LIBUV_DIR}/src/win/signal.c
    ${LIBUV_DIR}/src/win/snprintf.c
    ${LIBUV_DIR}/src/win/stream-inl.h
    ${LIBUV_DIR}/src/win/stream.c
    ${LIBUV_DIR}/src/win/tcp.c
    ${LIBUV_DIR}/src/win/thread.c
    ${LIBUV_DIR}/src/win/timer.c
    ${LIBUV_DIR}/src/win/tty.c
    ${LIBUV_DIR}/src/win/udp.c
    ${LIBUV_DIR}/src/win/util.c
    ${LIBUV_DIR}/src/win/winapi.c
    ${LIBUV_DIR}/src/win/winapi.h
    ${LIBUV_DIR}/src/win/winsock.c
    ${LIBUV_DIR}/src/win/winsock.h
  )
else()
  include_directories(${LIBUV_DIR}/src/unix)
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/include/uv-unix.h
    ${LIBUV_DIR}/include/uv-linux.h
    ${LIBUV_DIR}/include/uv-sunos.h
    ${LIBUV_DIR}/include/uv-bsd.h
    ${LIBUV_DIR}/include/uv-aix.h
    ${LIBUV_DIR}/src/unix/async.c
    ${LIBUV_DIR}/src/unix/atomic-ops.h
    ${LIBUV_DIR}/src/unix/core.c
    ${LIBUV_DIR}/src/unix/device.c
    ${LIBUV_DIR}/src/unix/dl.c
    ${LIBUV_DIR}/src/unix/fs.c
    ${LIBUV_DIR}/src/unix/getaddrinfo.c
    ${LIBUV_DIR}/src/unix/getnameinfo.c
    ${LIBUV_DIR}/src/unix/internal.h
    ${LIBUV_DIR}/src/unix/loop-watcher.c
    ${LIBUV_DIR}/src/unix/loop.c
    ${LIBUV_DIR}/src/unix/pipe.c
    ${LIBUV_DIR}/src/unix/poll.c
    ${LIBUV_DIR}/src/unix/process.c
    ${LIBUV_DIR}/src/unix/proctitle.c
    ${LIBUV_DIR}/src/unix/signal.c
    ${LIBUV_DIR}/src/unix/spinlock.h
    ${LIBUV_DIR}/src/unix/stream.c
    ${LIBUV_DIR}/src/unix/tcp.c
    ${LIBUV_DIR}/src/unix/thread.c
    ${LIBUV_DIR}/src/unix/timer.c
    ${LIBUV_DIR}/src/unix/tty.c
    ${LIBUV_DIR}/src/unix/udp.c
  )
endif()

check_type_size("void*" SIZEOF_VOID_P)
if(SIZEOF_VOID_P EQUAL 8)
  add_definitions(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE)
endif()

## Freebsd
if("${CMAKE_SYSTEM_NAME}" MATCHES "FreeBSD")
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/src/unix/kqueue.c
    ${LIBUV_DIR}/src/unix/freebsd.c
  )
endif()

## OpenBSD
if("${CMAKE_SYSTEM_NAME}" MATCHES "OpenBSD")
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/src/unix/kqueue.c
    ${LIBUV_DIR}/src/unix/openbsd.c
  )
endif()

## Linux
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
  add_definitions(
    -D_GNU_SOURCE
  )
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/src/unix/proctitle.c
    ${LIBUV_DIR}/src/unix/linux-core.c
    ${LIBUV_DIR}/src/unix/linux-inotify.c
    ${LIBUV_DIR}/src/unix/linux-syscalls.c
    ${LIBUV_DIR}/src/unix/linux-syscalls.h
    ${LIBUV_DIR}/src/unix/procfs-exepath.c
    ${LIBUV_DIR}/src/unix/sysinfo-loadavg.c
    ${LIBUV_DIR}/src/unix/sysinfo-memory.c
  )
endif()

## SunOS
if("${CMAKE_SYSTEM_NAME}" MATCHES "SunOS")
  add_definitions(
    -D__EXTENSIONS__
    -D_XOPEN_SOURCE=500
  )
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/src/unix/sunos.c
  )
endif()

## Darwin
if(APPLE)
  add_definitions(
    -D=_DARWIN_USE_64_BIT_INODE
  )
  set(SOURCES ${SOURCES}
    ${LIBUV_DIR}/include/uv-darwin.h
    ${LIBUV_DIR}/src/unix/bsd-ifaddrs.c
    ${LIBUV_DIR}/src/unix/darwin.c
    ${LIBUV_DIR}/src/unix/darwin-proctitle.c
    ${LIBUV_DIR}/src/unix/fsevents.c
    ${LIBUV_DIR}/src/unix/kqueue.c
  )
endif()

add_library(uv STATIC ${SOURCES})
set_property(TARGET uv PROPERTY POSITION_INDEPENDENT_CODE ON)

if("${CMAKE_SYSTEM_NAME}" MATCHES "FreeBSD")
  target_link_libraries(uv
    pthread
    kvm
  )
endif()

if("${CMAKE_SYSTEM_NAME}" MATCHES "OpenBSD")
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  target_link_libraries(uv Threads::Threads)
endif()

if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
  target_link_libraries(uv
    pthread
  )
endif()

if(WIN32)
  if (MSVC)
  target_link_libraries(uv
    ws2_32.lib
    shell32.lib
    psapi.lib
    iphlpapi.lib
    advapi32.lib
    userenv.lib
  )
  elseif (MINGW)
  target_link_libraries(uv
    ws2_32
    shell32
    psapi
    iphlpapi
    advapi32
    userenv
  )
  endif()
endif()

if("${CMAKE_SYSTEM_NAME}" MATCHES "SunOS")
  target_link_libraries(uv
    kstat
    socket
    sendfile
  )
endif()

if(APPLE)
  find_library(FOUNDATION_LIBRARY Foundation)
  find_library(CORESERVICES_LIBRARY CoreServices)
  find_library(APPLICATION_SERVICES_LIBRARY ApplicationServices)
  target_link_libraries(uv
    ${FOUNDATION_LIBRARY}
    ${CORESERVICES_LIBRARY}
    ${APPLICATION_SERVICES_LIBRARY}
  )
endif()
