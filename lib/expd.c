#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <limits.h>
/*  三个有关 lua 的头文件   */
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
/*  库 open 函数的前置声明   */
int luaopen_mt(lua_State *L);
/*  一个函数功能的实现：对 usleep 做封装   */
/* seconds --
 * interval units -- */
static int mt_sleep(lua_State *L)
{
   lua_Number interval = luaL_checknumber(L, 1);
   lua_Number units = luaL_optnumber(L, 2, 1);
   usleep(1000000 * interval / units);
   return 0;
}
/*  将定义的函数名集成到一个结构数组中去，建立 lua 中使用的方法名与 C 的函数名的对应关系   */
static const luaL_reg mt_lib[] = {
   {"sleep", mt_sleep},
   {0,0}
}
/*  库打开时的执行函数（相当于这个库的 main 函数），执行完这个函数后， lua 中就可以加载这个 so 库了   */
int luaopen_mt(lua_State *L)
{
   /*  把那个结构体数组注册到 mt （名字可自己取）库中去 */
   luaL_register(L, "mt", mt_lib);
   return 1;
}