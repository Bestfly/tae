#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int isquare(lua_State *L){              /* C中的函数名 */
    float rtrn = lua_tonumber(L, -1);      /* 从Lua虚拟机里取出一个变量，这个变量是number类型的 */
    printf("Top of square(), nbr=%f\n",rtrn);
    lua_pushnumber(L,rtrn*rtrn);           /* 将返回值压回Lua虚拟机的栈中 */
    return 1;                              /* 这个返回值告诉lua虚拟机，我们往栈里放入了多少个返回值 */
}

int luaopen_power(lua_State *L){
    lua_register(
            L,               /* Lua 状态机 */
            "square",        /*Lua中的函数名 */
            isquare          /*当前文件中的函数名 */
            );
    lua_register(L,"cube",icube);
    return 0;
}