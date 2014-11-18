#!/bin/bash
#********************************#
#并发运行的shell                   #
#for huangqi v20141011           #
#note:                           #
#fun_num fun函数后台运行次数        #
#lua_num 每个程序lua运行次数        #
#********************************#
# cat fun_3.log | grep 'ms elapsed time:' | awk  -F ' ' '{print $4 $5}'|sort -n
# cat bj.log | grep 'ms elapsed time:' | awk  -F ' ' '{print $5}' | sort -n
fun()
{
#函数并发次数
fun_num=2
#函数内lua执行次数
lua_num=10
for ((j=1;j<=$fun_num;j++));do
{
random_num=`echo  $RANDOM`
echo "第$j个函数"
            for ((i=1;i<=$lua_num;i++));do
                lua qunar.lua  <<GETRECODE  >>fun_$j.log
                    CALL fun_accountbycustid(2,0,10.$random_num)
GETRECODE
                echo "第$j个函数 第$i次"
                echo "第$j个函数 第$i次"  >>call.log
            done
                echo "第$j个函数执行完成......"
}&
			done
    			wait
}
main()
{
	fun
}
main
exit 0