#!/usr/bin/env bash
set -e

echo "开始部署网站..."
docker compose config -q
docker compose up -d
docker compose ps
echo "部署完成。"	
