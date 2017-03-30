@echo off

set VS=14
if "%configuration%"=="2015" (set VS=14)
if "%configuration%"=="2013" (set VS=12)

if not defined platform set platform=x64
if "%platform%" EQU "x64" (set VS=%VS% Win64)

SET LIBUV_DIR=E:/work/portable/libuv
SET LUAJIT_DIR=E:/work/lua/LuaJIT

cmake -H. -Bbuild -G "NMake Makefiles"
cmake --build build --config Release
copy build\luv.dll .
copy build\luajit.exe .
