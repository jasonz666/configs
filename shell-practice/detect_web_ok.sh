#!/bin/bash
# detect_web_ok.sh

check_ok(){
    url='http://www.apelearn.com/bbs/forum.php'
    curl -I $url >/tmp/web_ok.txt 2>/dev/null
    grep -iq '200 OK' /tmp/web_ok.txt 2>/dev/null
}

# 每分钟检查网页是否可访问
while :; do
    check_ok
    if [ $? -eq 0 ]; then
        echo "`date '+%F %T'` check web $url, status OK" >>/tmp/web_ok_status.txt
    else
        echo "`date '+%F %T'` check web $url, status FAILED" >>/tmp/web_ok_status.txt
    fi
    sleep 60
done
