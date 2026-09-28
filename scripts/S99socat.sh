```sh
#!/bin/sh
# 放到 /koolshare/init.d/ 文件夹
# chmod +x S99socat.sh
#
# 用于：
# 1. 将公网 IPv6 端口转发到内网 IPv4
# 2. 检查 DDNS 注册状态
# 3. 定时检查 socat 和 DDNS 状态
#
# 示例：
# SOCAT_FORWARDS=dsm:192.168.100.4:5001
#
# 定时任务：
# SOCAT_INTERVAL=10 表示每 10 分钟检查一次


SOCAT_INTERVAL=10

# 格式：
# name:ip:port,name:ip:port
SOCAT_FORWARDS="dsm:192.168.100.4:5001"


get() {
    a="$(nvram get "$1")"
    echo "$a"
}


############################################################
# 启动 socat
############################################################
start_socat() {
    name="$1"
    ip="$2"
    port="$3"

    echo "$name $ip $port"

    # 检查当前端口对应的 socat 是否已经运行
    if [ -z "$(ps | grep '[s]ocat' | grep "TCP6-LISTEN:$port")" ]; then

        nohup socat \
            "TCP6-LISTEN:$port,reuseaddr,fork" \
            "TCP4:$ip:$port" \
            >/dev/null 2>&1 &

        logger -st "($(basename "$0"))" $$ \
            "启动成功 $name：socat TCP6-LISTEN:$port,reuseaddr,fork TCP4:$ip:$port"
    fi

    open_port_ip6tables "$port"
}


############################################################
# 开放 IPv6 防火墙端口
############################################################
open_port_ip6tables() {
    port="$1"

    # 精确检查 INPUT 规则
    if ! ip6tables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1; then

        ip6tables -I INPUT -p tcp --dport "$port" -j ACCEPT

        logger -st "($(basename "$0"))" $$ \
            "ip6tables添加成功：ip6tables -I INPUT -p tcp --dport $port -j ACCEPT"
    fi
}


############################################################
# 关闭 IPv6 防火墙端口
############################################################
close_port_ip6tables() {
    port="$1"

    # 删除所有完全匹配的规则
    while ip6tables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1
    do
        ip6tables -D INPUT -p tcp --dport "$port" -j ACCEPT

        logger -st "($(basename "$0"))" $$ \
            "ip6tables删除成功：ip6tables -D INPUT -p tcp --dport $port -j ACCEPT"
    done
}


############################################################
# 停止指定端口对应的 socat
############################################################
stop_socat() {
    name="$1"
    ip="$2"
    port="$3"

    logger -st "($(basename "$0"))" $$ \
        "开始停止 $name：TCP6-LISTEN:$port -> TCP4:$ip:$port"

    # 找到监听指定 IPv6 端口的 socat PID
    pids="$(ps | grep '[s]ocat' | grep "TCP6-LISTEN:$port" | awk '{print $1}')"

    if [ -n "$pids" ]; then
        for pid in $pids
        do
            kill "$pid" 2>/dev/null

            logger -st "($(basename "$0"))" $$ \
                "停止socat成功：PID=$pid，端口=$port"
        done
    else
        logger -st "($(basename "$0"))" $$ \
            "socat未运行：端口=$port"
    fi

    # 关闭 IPv6 防火墙端口
    close_port_ip6tables "$port"
}


############################################################
# 批量启动 socat
############################################################
batch_start_socat() {

    OLD_IFS="$IFS"
    IFS=","

    for item in $SOCAT_FORWARDS
    do
        IFS=":"
        set -- $item

        name="$1"
        ip="$2"
        port="$3"

        IFS="$OLD_IFS"

        start_socat "$name" "$ip" "$port"
    done

    IFS="$OLD_IFS"
}


############################################################
# 批量停止 socat
############################################################
batch_stop_socat() {

    OLD_IFS="$IFS"
    IFS=","

    for item in $SOCAT_FORWARDS
    do
        IFS=":"
        set -- $item

        name="$1"
        ip="$2"
        port="$3"

        IFS="$OLD_IFS"

        stop_socat "$name" "$ip" "$port"
    done

    IFS="$OLD_IFS"
}


############################################################
# 添加定时任务
############################################################
write_cron_job() {

    # 每 SOCAT_INTERVAL 分钟检查一次
    if [ -z "$(cru l | grep '[s]ocat_check')" ]; then

        cru a socat_check \
            "*/$SOCAT_INTERVAL * * * * $(readlink -f "$0")"

        logger -st "($(basename "$0"))" $$ \
            "添加socat_check定时更新任务..."
    fi
}


############################################################
# 删除定时任务
############################################################
kill_cron_job() {

    if [ -n "$(cru l | grep '[s]ocat_check')" ]; then

        cru d socat_check

        logger -st "($(basename "$0"))" $$ \
            "删除socat_check定时任务..."
    fi
}


############################################################
# DDNS 状态检查
############################################################
check_ddns() {

    asusddns_token_state="$(get asusddns_token_state)"

    if [ "$asusddns_token_state" = "-3" ]; then

        logger -st "($(basename "$0")" $$ \
            "ddns状态异常，正在强制更新 $asusddns_token_state"

        service restart_ddns_le

        # /usr/sbin/inadyn --once --force -n
    fi
}


############################################################
# 启动时执行全部任务
############################################################
exec_all_job() {

    # 1. socat 运行检查
    batch_start_socat

    # 2. DDNS 注册状态检查
    check_ddns

    # 3. 检查定时任务
    write_cron_job
}


############################################################
# 停止时执行全部清理
############################################################
stop_all_job() {

    # 1. 删除定时任务
    kill_cron_job

    # 2. 停止 socat
    batch_stop_socat
}


############################################################
# 主程序
############################################################
action="$1"

case "$action" in

start)
    logger -st "($(basename "$0"))" $$ \
        "[socat]: 开始执行socat脚本"

    exec_all_job
    ;;

stop|kill)
    logger -st "($(basename "$0"))" $$ \
        "[socat]: 开始停止socat并删除防火墙规则"

    stop_all_job
    ;;

restart)
    logger -st "($(basename "$0"))" $$ \
        "[socat]: 开始重启socat"

    stop_all_job
    exec_all_job
    ;;

*)
    batch_start_socat
    exec_all_job
    ;;

esac
```
