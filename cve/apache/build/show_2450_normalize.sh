#!/bin/bash
# 读取 2.4.50 的 ap_normalize_path 关键段，便于报告准确引用“不完整修复”
sed -n '520,600p' /root/work/miner/src/httpd-2.4.50/server/util.c
