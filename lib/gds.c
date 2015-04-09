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

static int mt_exp(lua_State * l)
{
    lua_pushstring(l,"hello lua");
    return 1;
}
/*  将定义的函数名集成到一个结构数组中去，建立 lua 中使用的方法名与 C 的函数名的对应关系   */
static const luaL_reg mt_lib[] = {
   {"exp",mt_exp},
   {0,0}
};
/*  库打开时的执行函数（相当于这个库的 main 函数），执行完这个函数后， lua 中就可以加载这个 so 库了   */
int luaopen_mt(lua_State *L)
{
   /*  把那个结构体数组注册到 mt （名字可自己取）库中去 */
   luaL_register(L, "mt", mt_lib);
   return 1;
}



#include <stdio.h>     
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
  
 
int luaopen_tt(lua_State * l);
//要想注册进lua，函数的定义为 typedef int (*lua_CFunction)(lua_State* L)
static int exp(lua_State * l)
{
    lua_pushstring(l,"hello lua");
    //返回值代表向栈内压入的元素个数
    return 1;
}
//把需要用到的函数都放到注册表中，统一进行注册
static const luaL_Reg lib[]=
{
    {"exp",exp},
    {0,0}
};
//把上边的函数封装到一个模块里边
int luaopen_tt(lua_State * l)
{
    luaL_register(l,"tt",lib);
    return 1;
}