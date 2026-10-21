#!/usr/bin/env bash
# 一键发布：推送代码 → 打 tag → 触发 GitHub Actions 构建未签名 HAP → 生成 Release。
#
# 前置：
#   1) PAT 需具备 Contents: Read and write、Workflows: Read and write、Actions: Read and write，
#      且 Repository access 包含本仓库（或 All repositories）。
#   2) 运行环境中设置 GITHUB_TOKEN（本机从 ~/.dsh/.env 读取）。
#
# 用法：
#   GITHUB_TOKEN=xxx ./publish.sh [tag]     # 默认 v0.1.0
set -euo pipefail

cd "$(dirname "$0")"
TAG="${1:-v0.1.0}"
REMOTE="https://github.com/ajawpwinner-del/dsh-harmony.git"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  if [ -f "$HOME/.dsh/.env" ]; then
    set -a; . "$HOME/.dsh/.env"; set +a
  fi
fi
[ -n "${GITHUB_TOKEN:-}" ] || { echo "GITHUB_TOKEN 未设置"; exit 1; }

AUTH_HEADER="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 -w0)"

git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE"
git -c credential.helper= -c http.https://github.com/.extraheader="$AUTH_HEADER" push -u origin main
git tag -f "$TAG"
git -c credential.helper= -c http.https://github.com/.extraheader="$AUTH_HEADER" push -f origin "$TAG"

echo "已推送 tag $TAG，Actions 构建中："
echo "  https://github.com/ajawpwinner-del/dsh-harmony/actions"
