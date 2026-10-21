#!/usr/bin/env bash
# 本地构建 + 直接调用 GitHub API 发布 Release（不依赖 Actions）。
# 适合 Actions 出问题或想立刻发包时使用；需要 PAT 具备 Contents: Read and write。
#
# 用法：GITHUB_TOKEN=xxx ./release-local.sh [tag]
set -euo pipefail
cd "$(dirname "$0")"
TAG="${1:-v0.1.0}"
REPO="ajawpwinner-del/dsh-harmony"
HAP="harmonyos/entry/build/default/outputs/default/entry-default-unsigned.hap"

[ -n "${GITHUB_TOKEN:-}" ] || { [ -f "$HOME/.dsh/.env" ] && set -a && . "$HOME/.dsh/.env" && set +a; }
[ -n "${GITHUB_TOKEN:-}" ] || { echo "GITHUB_TOKEN 未设置"; exit 1; }

echo "== 1/3 构建未签名 HAP"
CLT="${CLT:-$HOME/ohos-sdk/command-line-tools}"
JDK="${JDK:-$HOME/jdk21}"
GL_LIB_DIR="${GL_LIB_DIR:-$HOME/gl-libs/usr/lib/x86_64-linux-gnu}"
export JAVA_HOME="$JDK" DEVECO_SDK_HOME="$CLT/sdk" DEVECO_CLI_CLT_PATH="$CLT"
export PATH="$CLT/bin:$CLT/tool/node/bin:$JAVA_HOME/bin:$PATH"
[ -d "$GL_LIB_DIR" ] && export LD_LIBRARY_PATH="$GL_LIB_DIR:$GL_LIB_DIR/dri:${LD_LIBRARY_PATH:-}"
export LIBGL_ALWAYS_SOFTWARE=1
cd harmonyos
[ -f local.properties ] || echo "sdk.dir=$DEVECO_SDK_HOME" > local.properties
hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon
cd ..
[ -f "$HAP" ] || { echo "未找到 $HAP"; exit 1; }
mkdir -p out && cp "$HAP" out/ && (cd out && sha256sum ./*.hap > SHA256SUMS)

echo "== 2/3 创建 Release $TAG"
API="https://api.github.com/repos/$REPO/releases"
BODY=$(printf '## 未签名 HAP\n\n- 资产：entry-default-unsigned.hap + SHA256SUMS\n- 本包未签名，不能直接 hdc install；请用 DevEco 自动签名或 hap-sign-tool 签名后安装。\n- 步骤见仓库 SIGNING.md。\n')
payload=$(python3 -c 'import json,sys;print(json.dumps({"tag_name":sys.argv[1],"name":"Unsigned HAP "+sys.argv[1],"body":sys.argv[2],"prerelease":True,"draft":False}))' "$TAG" "$BODY")
release=$(curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H 'Accept: application/vnd.github+json' "$API" -d "$payload")
echo "$release" | head -c 300; echo
upload=$(echo "$release" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("upload_url","").split("{")[0])')
[ -n "$upload" ] || { echo "创建 Release 失败"; exit 1; }

echo "== 3/3 上传资产"
for f in out/entry-default-unsigned.hap out/SHA256SUMS; do
  curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H 'Content-Type: application/octet-stream' \
    --data-binary @"$f" "$upload?name=$(basename "$f")" -o /dev/null -w "upload $(basename "$f"): %{http_code}\n"
done
echo "完成：https://github.com/$REPO/releases/tag/$TAG"
