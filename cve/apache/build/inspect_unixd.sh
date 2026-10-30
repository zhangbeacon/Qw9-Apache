#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== unixd drop privileges ====="
grep -n "MUST relinquish\|running as root\|user_id\|geteuid" os/unix/unixd.c | head -30
sed -n '/static int unixd_set_user/,/^}/p' os/unix/unixd.c
echo "===== default User/Group ====="
grep -n "User\|Group" docs/conf/httpd.conf | grep -i "user daemon\|group daemon\|User \|Group " | head
echo "===== config default user ====="
grep -n "user_id\|group_id" os/unix/unixd.c | head -20
