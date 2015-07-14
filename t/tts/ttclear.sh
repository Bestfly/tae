#!/bin/bash
#请正确设置下面的三个关键变量，目录的话不要用/结尾
TT_INSTALL_HOME="/usr/local/bin"                                                  #TTServer 安装文件目录
DIR_ULOG="/mnt/dc/data/rankbus"   #ulog所在目录
TT_SERVICE_PORT="11978"
#以上三个变量请务必设置正确
cd $DIR_ULOG
ULOG_FILE_COUNT=`find $DIR_ULOG -name '*.ulog' | wc -l`         #获取ULOG文件数量
JUMP_FILE_COUNT=0                                               #ULOG文件不删除文件计数
STR_CURTIME=`date +"%Y-%m-%d %H:%M:%S"`                         #当前的系统时间
DATA_CURTIME=`date -d  "$STR_CURTIME" +%s`                      #转换成秒
PROCESS_RES_FILE="$DIR_ULOG/clear/res.txt"				#处理日志输出文件
echo "ulog dir : " $DIR_ULOG
echo System time is $STR_CURTIME
echo "Ulog file count : " $ULOG_FILE_COUNT
$TT_INSTALL_HOME/tcrmgr optimize -port $TT_SERVICE_PORT localhost
echo "********   Start clear ulog file!   ********" >> $PROCESS_RES_FILE
DELAY_TIME=$($TT_INSTALL_HOME/tcrmgr inform -port $TT_SERVICE_PORT -st localhost | awk '$1=="delay"''{print $2}')
if [ -z $DELAY_TIME ]
then
	DELAY_TIME=60							   #如果无法查询得到复制延迟，那么设定延迟时间为60秒
fi
DELAY_TIME=$(printf %.0f $DELAY_TIME)					   #将时差四舍五入为整数
for ULOG_FILE in `ls -t $DIR_ULOG | awk '{print $1}'`
	do
		FILE_SUFFIX=${ULOG_FILE##*.}                               #获取文件后缀名
		STR_LASTTIME=$(ls -lt $ULOG_FILE | awk '{print $6,$7}')    #获取文件的最后时间
		DATA_LASTTIME=`date -d  "$STR_LASTTIME" +%s`  		   #转换成秒
		INTERVAL_TIME=`expr $DATA_CURTIME - $DATA_LASTTIME`        #计算2个时间的差
		if [ $INTERVAL_TIME -gt $DELAY_TIME -a $FILE_SUFFIX = "ulog" ]
		then
			if [ $JUMP_FILE_COUNT -lt 2 ] 			   #最后保留两个最新的ULOG文件，即使这个ULOG最后修改时间和当前时间的差大于同步时差。
			then
				((JUMP_FILE_COUNT=$JUMP_FILE_COUNT + 1))
				continue
			fi
			echo file will be deleted: $ULOG_FILE $INTERVAL_TIME S >> $DIR_ULOG/res.txt
			#rm -rf $ULOG_FILE
		fi
	done
echo "********   ULog file cleared up!   ********" >> $PROCESS_RES_FILE
