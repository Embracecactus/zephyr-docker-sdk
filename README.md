# zephyr-docker-sdk

English | [简体中文](#简体中文)

A lightweight Docker/Compose environment for building Zephyr projects with configurable Zephyr SDK versions.

This project is community-maintained and is not affiliated with the official Zephyr project Docker images.

## English

### Features

- Ubuntu 24.04 based development image
- Zephyr SDK 1.0.1 by default
- Configurable SDK version, SDK toolchains, and base image
- Optional local SDK archive cache for slow networks
- Docker Compose workflow with persistent ccache
- Automatic Python requirements sync from `$ZEPHYR_BASE/scripts/requirements.txt`

### Quick start

```bash
git clone https://github.com/Embracecactus/zephyr-docker-sdk.git
cd zephyr-docker-sdk
```

Set your Zephyr workspace path. For example, if your host workspace is `/path/to/zephyr-workspace` and the Zephyr repository inside it is named `zephyr`:

```bash
export ZEPHYR_WORKSPACE=/path/to/zephyr-workspace
export ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr
```

If your repository directory has a different name, set `ZEPHYR_BASE` accordingly, for example `/workspace/zephyr-workspace/<zephyr-repo-dir>`.

For a standard workspace with a `zephyr` repository, you can omit `ZEPHYR_BASE` and use the default:

```text
/workspace/zephyr-workspace/zephyr
```

Build the image:

```bash
docker compose build
```

Start and enter the container:

```bash
docker compose up -d
docker compose exec zephyr-sdk bash
```

Verify inside the container:

```bash
echo $ZEPHYR_BASE
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_TOOLCHAIN_VARIANT
west --version
arm-zephyr-eabi-gcc --version
```

Build a Zephyr sample inside the container:

```bash
cd $ZEPHYR_BASE
west build -p always -b <board> samples/hello_world
```

### Local SDK archive cache

Downloading the Zephyr SDK inside `docker build` can be slow and hard to resume. You can download the SDK archive on the host first:

```bash
mkdir -p cache
wget -c -O cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v1.0.1/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
```

Then build normally:

```bash
docker compose build
```

The Dockerfile uses `cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz` if it exists, and falls back to downloading from GitHub when the cache file is missing.

Do not commit SDK archives. `.gitignore` excludes `cache/*.tar.xz`; only `cache/.gitkeep` is tracked.

### Configuration

You can override these variables:

| Variable | Default | Description |
|---|---|---|
| `BASE_IMAGE` | `docker.1ms.run/library/ubuntu:24.04` | Base Ubuntu image. Use `ubuntu:24.04` if Docker Hub is reachable. |
| `ZSDK_VERSION` | `1.0.1` | Zephyr SDK version. |
| `SDK_TOOLCHAINS` | `all` | Toolchains installed by `setup.sh -t`. Use `arm-zephyr-eabi` for smaller ARM-only images. |
| `HOSTTYPE` | `x86_64` | Host architecture used in the SDK archive name. |
| `ZEPHYR_WORKSPACE` | `./workspace` | Host path mounted to `/workspace/zephyr-workspace`. |
| `ZEPHYR_BASE` | `/workspace/zephyr-workspace/zephyr` | Zephyr repository path inside the container. |
| `SKIP_ZEPHYR_PIP_SYNC` | `0` | Set to `1` to skip automatic `pip install -r $ZEPHYR_BASE/scripts/requirements.txt`. |

Example:

```bash
BASE_IMAGE=ubuntu:24.04 \
ZSDK_VERSION=1.0.1 \
SDK_TOOLCHAINS=arm-zephyr-eabi \
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace \
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr \
docker compose build
```

### Common issues

#### Docker Hub is not reachable

The default base image uses a Docker Hub mirror:

```text
docker.1ms.run/library/ubuntu:24.04
```

To use the official image instead:

```bash
BASE_IMAGE=ubuntu:24.04 docker compose build
```

#### SDK archive is not a valid tar.xz

Check the file:

```bash
file cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
xz -t cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
```

If it is invalid, remove it and download again with `wget -c`.

#### CMake still finds an old SDK

Check inside the container:

```bash
echo $ZEPHYR_SDK_INSTALL_DIR
ls -d /opt/toolchains/zephyr-sdk-*
```

The default expected value is:

```text
/opt/toolchains/zephyr-sdk-1.0.1
```

### What is not included

This repository does not include:

- Zephyr SDK tarballs
- Docker image archives
- Zephyr source code
- Board-specific patches

It only contains Docker build and Compose files.

---

## 简体中文

一个轻量级 Docker/Compose 环境，用于基于 Zephyr SDK 构建 Zephyr 项目，并支持自定义 Zephyr SDK 版本。

本项目由社区维护，不隶属于 Zephyr 官方 Docker 镜像项目。

### 功能特性

- 基于 Ubuntu 24.04 的开发镜像
- 默认使用 Zephyr SDK 1.0.1
- 支持配置 SDK 版本、安装的 SDK toolchains、基础镜像
- 支持本地 SDK 压缩包缓存，适合网络较慢或 GitHub 下载不稳定的环境
- 使用 Docker Compose 管理开发容器，并持久化 ccache
- 容器启动时可自动同步 `$ZEPHYR_BASE/scripts/requirements.txt` 中的 Python 依赖

### 快速开始

```bash
git clone https://github.com/Embracecactus/zephyr-docker-sdk.git
cd zephyr-docker-sdk
```

设置你的 Zephyr 工作区路径。比如宿主机工作区是 `/path/to/zephyr-workspace`，里面的 Zephyr 仓库名是 `zephyr`：

```bash
export ZEPHYR_WORKSPACE=/path/to/zephyr-workspace
export ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr
```

如果你的仓库目录不是 `zephyr`，请按实际目录名设置 `ZEPHYR_BASE`，例如 `/workspace/zephyr-workspace/<zephyr-repo-dir>`。

如果你的工作区里 Zephyr 仓库名就是标准的 `zephyr`，可以不设置 `ZEPHYR_BASE`，默认值是：

```text
/workspace/zephyr-workspace/zephyr
```

构建镜像：

```bash
docker compose build
```

启动并进入容器：

```bash
docker compose up -d
docker compose exec zephyr-sdk bash
```

在容器内验证环境：

```bash
echo $ZEPHYR_BASE
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_TOOLCHAIN_VARIANT
west --version
arm-zephyr-eabi-gcc --version
```

在容器内构建 Zephyr 示例：

```bash
cd $ZEPHYR_BASE
west build -p always -b <board> samples/hello_world
```

### 本地 SDK 压缩包缓存

在 `docker build` 过程中直接下载 Zephyr SDK 可能很慢，而且中断后不方便续传。建议先在宿主机下载 SDK 压缩包：

```bash
mkdir -p cache
wget -c -O cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v1.0.1/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
```

然后正常构建：

```bash
docker compose build
```

如果 `cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz` 存在，Dockerfile 会优先使用这个本地文件；如果不存在，才会回退到 GitHub 下载。

不要提交 SDK 压缩包。`.gitignore` 已经排除了 `cache/*.tar.xz`，只跟踪 `cache/.gitkeep`。

### 配置项

可以通过环境变量覆盖这些默认值：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `BASE_IMAGE` | `docker.1ms.run/library/ubuntu:24.04` | 基础 Ubuntu 镜像。如果 Docker Hub 可访问，可以改成 `ubuntu:24.04`。 |
| `ZSDK_VERSION` | `1.0.1` | Zephyr SDK 版本。 |
| `SDK_TOOLCHAINS` | `all` | `setup.sh -t` 安装的 toolchains。只做 ARM 构建时可用 `arm-zephyr-eabi` 减小镜像体积。 |
| `HOSTTYPE` | `x86_64` | SDK 压缩包文件名里的主机架构。 |
| `ZEPHYR_WORKSPACE` | `./workspace` | 宿主机 Zephyr 工作区路径，挂载到容器内 `/workspace/zephyr-workspace`。 |
| `ZEPHYR_BASE` | `/workspace/zephyr-workspace/zephyr` | 容器内 Zephyr 仓库路径。 |
| `SKIP_ZEPHYR_PIP_SYNC` | `0` | 设置为 `1` 可跳过自动执行 `pip install -r $ZEPHYR_BASE/scripts/requirements.txt`。 |

示例：

```bash
BASE_IMAGE=ubuntu:24.04 \
ZSDK_VERSION=1.0.1 \
SDK_TOOLCHAINS=arm-zephyr-eabi \
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace \
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr \
docker compose build
```

### 常见问题

#### Docker Hub 无法访问

默认基础镜像使用 Docker Hub 镜像源：

```text
docker.1ms.run/library/ubuntu:24.04
```

如果想使用官方镜像：

```bash
BASE_IMAGE=ubuntu:24.04 docker compose build
```

#### SDK 压缩包不是有效的 tar.xz

检查文件：

```bash
file cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
xz -t cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
```

如果检查失败，删除后用 `wget -c` 重新下载。

#### CMake 仍然找到旧 SDK

在容器内检查：

```bash
echo $ZEPHYR_SDK_INSTALL_DIR
ls -d /opt/toolchains/zephyr-sdk-*
```

默认期望值是：

```text
/opt/toolchains/zephyr-sdk-1.0.1
```

### 本仓库不包含什么

本仓库不包含：

- Zephyr SDK 压缩包
- Docker 镜像归档
- Zephyr 源码
- 特定开发板补丁

本仓库只包含 Docker 构建文件和 Docker Compose 配置。
