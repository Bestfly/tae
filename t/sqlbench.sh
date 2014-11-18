#!/bin/bash
#********************************#
#并发后台运行fun                   #
#for wanggy 2012-01-25           #
#note:                           #
#fun_num fun函数后台运行次数        #
#sql_num 每个函数sql运行次数        #
#********************************#
#数据库变量设置
#dbhost=192.168.1.182
#dbbase=recharge
#dbuser=infosms
#dbpass=infosms
fun()
{
	#函数并发次数
	fun_num=5
	#函数内sql执行次数
	sql_num=1000
	for ((j=1;j<=$fun_num;j++));do
	{
		random_num=`echo  $RANDOM`
		echo "第$j个函数"
		            for ((i=1;i<=$call_num;i++));do
		                mysql -h$dbhost -u$dbuser -p$dbpass -D$dbbase  <<GETRECODE  >>fun_$j.log
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