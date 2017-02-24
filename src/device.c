/*
 *  Copyright 2014 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
#include "luv.h"

static uv_device_t* luv_check_device(lua_State* L, int index) {
  uv_device_t* handle = *(void**)luaL_checkudata(L, index, "uv_device");
  luaL_argcheck(L, handle->type == UV_DEVICE && handle->data, index, "Expected uv_device_t");
  return handle;
}

static int luv_new_device(lua_State* L) {
  int ret;
  const char* path = luaL_checkstring(L, 1);
  int flags = luv_check_flags(L, 2);
  uv_device_t* handle = luv_newuserdata(L, sizeof(*handle));

  ret = uv_device_init(luv_loop(L), handle, path, flags);
  if (ret < 0) {
    lua_pop(L, 1);
    return luv_error(L, ret);
  }
  handle->data = luv_setup_handle(L);
  return 1;
}

static int luv_device_ioctl(lua_State* L) {
  uv_device_t* handle = luv_check_device(L, 1);
  int cmd = luaL_checkint(L, 2);
  uv_ioargs_t args = {0};
  int ret;
#ifdef WIN32
  if (!lua_isnoneornil(L, 3)) {
    args.input = (void*)luaL_checklstring(L, 3, &args.input_len);
  }
  if (!lua_isnoneornil(L, 4)) {
    args.output = (void*)luaL_checklstring(L, 4, &args.output_len);
  }
#else
  if (lua_isnumber(L, 3)) {
    args.arg = (void*)lua_tointeger(L, 3);
  } else if (!lua_isnoneornil(L, 3)) {
    args.arg = lua_tostring(L,3);
  }else {
    luaL_argerror(L, 3, "not accept data type");
  }
#endif
  ret = uv_device_ioctl(handle, cmd, &args);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}
