#!/usr/bin/env bash
# 在本机（Linux VPS）复现未签名 HAP 构建。
# 依赖：官方 HarmonyOS Command Line Tools（26.0.0.x）、JDK 21、Mesa GL 运行库。
# 说明：CompileResource 需要 libGL.so.1。没有 root 时可以从 Debian 包解出 GL 库，
#       用 LD_LIBRARY_PATH 指向（见下方 GL_LIB_DIR）。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLT="${CLT:-$HOME/ohos-sdk/command-line-tools}"
JDK="${JDK:-$HOME/jdk21}"
GL_LIB_DIR="${GL_LIB_DIR:-$HOME/gl-libs/usr/lib/x86_64-linux-gnu}"

export JAVA_HOME="$JDK"
export DEVECO_SDK_HOME="$CLT/sdk"
export DEVECO_CLI_CLT_PATH="$CLT"
export PATH="$CLT/bin:$CLT/tool/node/bin:$JAVA_HOME/bin:$PATH"
[ -d "$GL_LIB_DIR" ] && export LD_LIBRARY_PATH="$GL_LIB_DIR:$GL_LIB_DIR/dri:${LD_LIBRARY_PATH:-}"
export LIBGL_ALWAYS_SOFTWARE=1

cd "$HERE/harmonyos"
[ -f local.properties ] || echo "sdk.dir=$DEVECO_SDK_HOME" > local.properties

hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon

echo "---"
find entry/build -name '*.hap' -exec sha256sum {} \;
