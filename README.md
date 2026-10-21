# dsh-harmony

云端 DeepSeek Harness（DSH）的**原生鸿蒙（HarmonyOS NEXT / ArkTS）客户端**，配套
[`dsh-remote-plugin`](https://github.com/Blank-not-black/dsh-Remote) 网关使用。

- 本仓库的 `harmonyos/` 工程来自 [Blank-not-black/dsh-Remote](https://github.com/Blank-not-black/dsh-Remote)
  的 `harmonyos/` 目录（MIT 许可，版权归原作者，见 `LICENSE` 与 `NOTICE`），用于**构建未签名 HAP**。
- 构建在 GitHub Actions 上完成（官方 HarmonyOS Command Line Tools 26.0.0.821），
  每次构建自动发布一个 **未签名 HAP** 的 Release 供下载。
- **签名由使用者本地完成**（DevEco Studio 自动签名，或 `hap-sign-tool` 手动签名），
  签名后再侧载到手机。详见 [`SIGNING.md`](SIGNING.md)。

## 下载

Release 页下载 `entry-default-unsigned.hap`（及 `SHA256SUMS`）。

## 构建

- 自动：仓库 **Actions → Build unsigned HAP → Run workflow**，填 tag（如 `v0.1.0`）；
  或推送 tag（`git tag v0.1.0 && git push origin v0.1.0`），会生成 Release。
- 本地（可选，需要 DevEco Studio 或官方 Command Line Tools ≥ 26.0.0）：

```sh
cd harmonyos
hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon
# 产物：entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 与云端 DSH 对接

1. 云端 DSH 安装 `dsh-remote-plugin` 并启动内置网关（默认端口 `8787`）；
2. 手机与网关网络互通（局域网 / Tailscale / 公网 TLS 反代，例如 `remote.nanqiaoclaw.cloud`）；
3. 打开 App → 设置 → 服务器 → 扫码连接（扫网关管理控制台里的配对二维码），或手动填写
   地址 + 令牌；
4. 连接后即可在手机上查看/操作会话、审批、提问、文件互传。

## 工程信息

- bundleName：`com.dshremote.app`，versionName `0.6.26` / versionCode `6269`
- targetSdkVersion `26.0.0`（HarmonyOS 7 / API 26），compatibleSdkVersion `6.1.1(24)`
- 零第三方运行时依赖（`oh-package.json5` 的 `dependencies` 为空）
