#!/usr/bin/env bash
# 用 GitHub CLI 的设备码登录结果推送 + 触发 Actions + 等待 Release。
# 前置：gh 已在本机登录（gh auth status 成功）。
set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/bin:$PATH"
TAG="${1:-v0.1.0}"

gh auth status >/dev/null 2>&1 || { echo "gh 未登录，先运行 gh auth login"; exit 1; }
gh auth setup-git

echo "== push main"
git push -u origin main

echo "== push tag $TAG"
git tag -f "$TAG"
git push -f origin "$TAG"

echo "== 等待 Actions 运行"
sleep 5
run_id=$(gh run list --workflow build-hap.yml --limit 1 --json databaseId --jq '.[0].databaseId')
echo "run id: $run_id"
if ! gh run watch "$run_id" --exit-status; then
  echo "== 构建失败，失败日志："
  gh run view "$run_id" --log-failed | tail -120
  exit 1
fi

echo "== Release 结果"
gh release view "$TAG" --json url,assets --jq '{url:.url,assets:[.assets[].name]}'
