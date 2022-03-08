#!/bin/sh
#
# 此程序用于在确认路由器已经成功启动后，执行用户自定义程序列表
#
########## PROHIBIT REDUNDANT INSTANCE ##########
#
# Enable lock 1
# 启用一号锁
chmod 000 "${0}"
#
ROUTER_MODEL="$(nvram get model)"
#
# NAME OF THE SERVICE
# 服务名称
SERVICE_NAME="usb_mount_script"
#
# FUNCTION OF THE SERVICE
# 服务功能
SERVICE_FUNCTION="BOOT"
#
# Detect lock 2
# 检测二号锁
if [ -e "/var/run/script_bootloader.pid" ]
then
    # Stop and Exit
    # 如果文件/var/run/script_bootloader.pid存在，则该程序终止
    logger -st "($(basename $0))" $$ "NOTICE: ${SERVICE_NAME} IS WORKING"
    #
    chmod 777 "${0}"
    #
    exit 1
else
    logger -st "($(basename $0))" $$ "*--------- ${SERVICE_FUNCTION} ${SERVICE_NAME} ON ${ROUTER_MODEL} ---------*"
fi
#
########## END ##########
#
#
########## CHECK ASUS ROUTER STATUS ##########
#
# Check if the router is ready for running user's custom scripts
# 检查路由器是否已经准备好执行用户自定义程序
#
# Check it out every 30 seconds in 5 minutes
# 每30秒检查1次，最多执行10次，最多用时5分钟
COUNT=0
while [ ${COUNT} -lt 10 ]
do
    SUCCESS_START_SERVICE=$(nvram get success_start_service)
    #
    if [ ${SUCCESS_START_SERVICE} -eq 1 ]
    then
        break
        #
    else
        logger -st "($(basename $0))" $$ "NOTICE: ${ROUTER_MODEL} IS NOT READY, WAIT 30 SECONDS MORE"
        sleep 30
        #
        COUNT=$((${COUNT}+1))
    fi
done
#
# Stop and Exit
# 如果10次检查均为路由器没准备好执行程序，则该程序终止
if [ ${SUCCESS_START_SERVICE} -ne 1 ]
then
    logger -st "($(basename $0))" $$ "NOTICE: ${ROUTER_MODEL} IS NOT READY"
    logger -st "($(basename $0))" $$ "FAILURE: ${SERVICE_FUNCTION} ${SERVICE_NAME}"
    #
    chmod 777 "${0}"
    #
    exit 2
fi
#
########## END ##########

########## EXCUTE START ##########

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))/scripts

#不存在scripts目录,创建
if [ ! -d "$SCRIPT_FOLDER" ]; then
  mkdir $SCRIPT_FOLDER
fi

for fileName  in ` ls $SCRIPT_FOLDER `
    do
        if [ -d $SCRIPT_FOLDER"/"$fileName  ]
        then
             echo "跳过目录$SCRIPT_FOLDER/$fileName"
        else
	     echo "开始自动执行$SCRIPT_FOLDER/$fileName"
             logger -st "($(basename $0))" $$ "开始自动执行$SCRIPT_FOLDER/$fileName"
             sh $SCRIPT_FOLDER/$fileName
        fi
    done

########## EXCUTE END ##########

########## NOTIFICATION ##########
#
logger -st "($(basename $0))" $$ "SUCCESS: ${SERVICE_FUNCTION} ${SERVICE_NAME}"
#
# Enable lock 2
# 启用二号锁
echo "Enable lock 2" > "/var/run/script_bootloader.pid"
#
# Disable lock 1
# 禁用一号锁
chmod 777 "${0}"
#
########## END ##########
