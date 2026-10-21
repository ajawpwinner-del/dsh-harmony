# 签名与侧载指南（你在本地做）

Release 里的 `entry-default-unsigned.hap` 是**未签名**包，**不能直接安装**。HarmonyOS 要求
HAP 带有效签名（证书 + Profile）才能安装到真机。下面两种方式任选其一。

> 工程信息：bundleName `com.dshremote.app`，targetSdk 26.0.0，compatibleSdk 6.1.1(24)。
> 手机需要：HarmonyOS 7（API 26）左右；开发者模式 + USB 调试。

## 方式一：DevEco Studio 自动签名（推荐，最省事）

1. 电脑安装 DevEco Studio（≥ 6.0，建议 26.0.0 Release），登录华为开发者账号；
2. `File → Open` 打开本仓库的 `harmonyos/` 目录；
3. `File → Project Structure → Signing Configs`，勾选 **Automatically generate signature**，
   按提示登录/同意，等待自动生成 `.p12/.cer/.p7b`（会写进本机 `build-profile.json5`，不要提交）；
4. 手机 USB 连接电脑并允许调试，`Run` 或 `Build → Build Hap(s)/APP(s)`；
5. 产物为已签名 `.hap`，DevEco 会直接装到设备（或 `hdc install -r <signed.hap>`）。

> 自动签名要求账号实名；调试证书绑定设备 UDID（`hdc shell bm get -u` 可查），
> 一台账号最多 100 台调试设备。

## 方式二：`hap-sign-tool` 手动签名（完全命令行）

工具在 Command Line Tools 的 `sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar`。

```sh
# 1) 生成密钥库与 CSR
keytool -genkeypair -alias dsh -keyalg EC -sigalg SHA256withECDSA \
  -dname "C=CN,O=DSH,OU=dev,CN=dsh" -keystore dsh.p12 -storetype pkcs12 \
  -storepass <口令> -keypass <口令> -validity 365
keytool -certreq -alias dsh -keystore dsh.p12 -storetype pkcs12 -storepass <口令> -file dsh.csr

# 2) 到 AGC（AppGallery Connect）申请：
#    - 设备管理：添加调试设备（UDID = hdc shell bm get -u）
#    - 证书：新增「调试证书」，上传 dsh.csr，下载 dsh.cer
#    - Profile：新增「调试」Profile，选该证书 + 调试设备，下载 dsh.p7b

# 3) 签名（参数以本机 hap-sign-tool 版本 --help 为准）
java -jar hap-sign-tool.jar sign-app \
  -keyAlias dsh -signAlg SHA256withECDSA \
  -mode localSign -appCertFile dsh.cer -profileFile dsh.p7b \
  -inFile entry-default-unsigned.hap -keystoreFile dsh.p12 \
  -outFile entry-default-signed.hap \
  -keyPwd <口令> -keystorePwd <口令> \
  -signCode 1
```

也可在 `harmonyos/build-profile.json5` 里配好 `signingConfigs`（`material.certpath / profile /
storeFile / storePassword / keyAlias / keyPassword`），再用 `hvigorw assembleHap` 直接产出已签名包。

## 安装到手机

```sh
hdc list targets                 # 确认设备已连接（USB 或 hdc tconn <ip>:<port>）
hdc install -r entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.dshremote.app
```

- 若提示签名冲突/版本冲突：先 `hdc uninstall com.dshremote.app` 再装。
- 手机开「设置 → 系统 → 开发者选项 → USB 调试」；无线调试可用 `hdc tconn <ip>:<port>`。
- 侧载包的有效期/可用设备由你的证书与 Profile 决定。

## 首次连接云端 DSH

1. 云端装好 `dsh-remote-plugin` 后，在 DSH 侧栏打开 **Remote**，启动网关（默认 `8787`）；
2. 手机与网关网络互通（局域网 / Tailscale / 公网 TLS 反代如 `https://remote.nanqiaoclaw.cloud`）；
3. App → 设置 → 服务器 → 扫码连接（扫控制台配对二维码）或手动填地址 + 令牌；
4. 建议先测：会话列表 → 打开会话 → 发一条消息 → 审批/文件。
