Harpia 定制了 Kubespray 的配置模板 `inventory/sample`，修改了其中部分配置以适应中国网络环境。
修改后的配置模板按 Kubespray 版本保存在 Harpia 的 `setup/inventory` 目录下。
对于 Kubespray 的发布版本，目录采用 `v2.8.3` 格式命名；对于非发布版本，采用精简的 Git 版本号命名。

## 如何演进 Kubespray 配置模板
当 Kubespray 发布新版本时，Harpia 需要同时演进 Kubespray 配置模板，以合并上游改动。

假设 Harpia 中保存的最新版本为 `v0.0.1`，而 Kubespray 上级演进到了 `v0.0.2`，则需要以下步骤演进
Harpia 中保存的配置模板：
1. 下载 `v0.0.2` 版本的 Kubespray 源码。假设其保存在了 `kubespray-v0.0.2`。
2. 复制一份 Harpia 中保存的 Kubespary 配置模板：
```shell
$ cd harpia/setup/inventory
inventory $ cp -rfp v0.0.1 v0.0.2
```
3. 使用您喜爱的工具例如 Meld 做三方合并，将上游的更改应用到 `v0.0.2`：
```shell
$ meld ../kubespray-v0.0.2/inventory/sample setup/inventory/v0.0.2 setup/inventory/v0.0.1
```
4. 修改 `docs/kubespray-zh_CN.md` 中相应章节，更新为新的 Kubespray 版本。

## 现有版本

* `9e8e069`: 带有 GPU 镜像源修复的 master 分支。
