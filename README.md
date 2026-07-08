# zephyr-docker-sdk

English | [简体中文](#简体中文)

A lightweight Docker image build project for Zephyr SDK based development environments.

This project builds a reusable Zephyr SDK Docker image. Project-specific workspace mounts, `ZEPHYR_BASE`, and extra volumes should be defined in your own `compose.yaml`, or by using `docker-compose.example.yml` as a template.

This project is community-maintained and is not affiliated with the official Zephyr project Docker images.

## English

### Features

- Ubuntu 24.04 based development image
- Zephyr SDK 1.0.1 by default
- Configurable SDK version, SDK toolchains, and base image
- Optional local SDK archive cache for slow networks
- Docker Compose workflow with persistent ccache
- Project workspace configuration kept outside the image
- Pre-installed Python dependencies for Zephyr builds: west, pyelftools, pyyaml, jsonschema, packaging, etc.
- Optional Python requirements sync from `$ZEPHYR_BASE/scripts/requirements.txt`

### Repository model

This repository is responsible for the generic image:

```text
Dockerfile + entrypoint.sh + image build compose
```

Your Zephyr project is responsible for the runtime workspace mapping:

```text
project compose.yaml -> ZEPHYR_WORKSPACE / ZEPHYR_BASE / project volumes
```

This keeps the image reusable across boards, SoCs, forks, and workspaces.

### Build the generic image

```bash
git clone https://github.com/Embracecactus/zephyr-docker-sdk.git
cd zephyr-docker-sdk
```

Build the default image:

```bash
docker compose build
```

This produces an image like:

```text
zephyr-docker-sdk:1.0.1
```

Start a plain shell from the generic image:

```bash
docker compose run --rm zephyr-sdk bash
```

### Use the image with a Zephyr workspace

Copy the example compose file into your own Zephyr project, or run it directly with environment variables:

```bash
cp .env.example .env
cp docker-compose.example.yml compose.yaml
```

Edit `.env` for your project:

```text
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr
```

Then start the project container:

```bash
docker compose -f compose.yaml up -d
docker compose -f compose.yaml exec zephyr-sdk bash
```

Inside the container:

```bash
echo $ZEPHYR_BASE
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_TOOLCHAIN_VARIANT
west --version
arm-zephyr-eabi-gcc --version
```

Build a Zephyr sample:

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

Image build variables:

| Variable | Default | Description |
|---|---|---|
| `BASE_IMAGE` | `docker.1ms.run/library/ubuntu:24.04` | Base Ubuntu image. Use `ubuntu:24.04` if Docker Hub is reachable. |
| `ZSDK_VERSION` | `1.0.1` | Zephyr SDK version. |
| `SDK_TOOLCHAINS` | `all` | Toolchains installed by `setup.sh -t`. Use `arm-zephyr-eabi` for smaller ARM-only images. |
| `HOSTTYPE` | `x86_64` | Host architecture used in the SDK archive name. |
| `IMAGE_NAME` | `zephyr-docker-sdk` | Output image name. |

Project runtime variables used by `docker-compose.example.yml`:

| Variable | Example | Description |
|---|---|---|
| `ZEPHYR_WORKSPACE` | `/path/to/zephyr-workspace` | Host workspace mounted to `/workspace/zephyr-workspace`. |
| `ZEPHYR_BASE` | `/workspace/zephyr-workspace/zephyr` | Zephyr repository path inside the container. |
| `SYNC_ZEPHYR_REQUIREMENTS` | `1` | Set to `1` to install `$ZEPHYR_BASE/scripts/requirements.txt` at container startup. |

Example image build:

```bash
BASE_IMAGE=ubuntu:24.04 \
ZSDK_VERSION=1.0.1 \
SDK_TOOLCHAINS=arm-zephyr-eabi \
docker compose build
```

Example project run:

```bash
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace \
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr \
docker compose -f docker-compose.example.yml up -d
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

一个轻量级 Docker 镜像构建项目，用于创建基于 Zephyr SDK 的开发环境。

本项目只负责构建可复用的 Zephyr SDK Docker 镜像。具体项目的 workspace 挂载、`ZEPHYR_BASE`、额外 volume 应该写在项目自己的 `compose.yaml` 中，或者基于 `docker-compose.example.yml` 模板修改。

本项目由社区维护，不隶属于 Zephyr 官方 Docker 镜像项目。

### 功能特性

- 基于 Ubuntu 24.04 的开发镜像
- 默认使用 Zephyr SDK 1.0.1
- 支持配置 SDK 版本、安装的 SDK toolchains、基础镜像
- 支持本地 SDK 压缩包缓存，适合网络较慢或 GitHub 下载不稳定的环境
- 使用 Docker Compose 管理镜像构建，并持久化 ccache
- 项目 workspace 配置不写死在镜像中
- 预装 Zephyr 构建所需的 Python 依赖：west、pyelftools、pyyaml、jsonschema、packaging 等
- 可选地从 `$ZEPHYR_BASE/scripts/requirements.txt` 同步 Python 依赖

### 仓库定位

本仓库负责通用镜像：

```text
Dockerfile + entrypoint.sh + 镜像构建 compose
```

你的 Zephyr 项目负责运行时 workspace 映射：

```text
项目 compose.yaml -> ZEPHYR_WORKSPACE / ZEPHYR_BASE / 项目 volume
```

这样同一个镜像可以复用于不同开发板、SoC、fork 和 workspace。

### 构建通用镜像

```bash
git clone https://github.com/Embracecactus/zephyr-docker-sdk.git
cd zephyr-docker-sdk
```

构建默认镜像：

```bash
docker compose build
```

会生成类似下面的镜像：

```text
zephyr-docker-sdk:1.0.1
```

从通用镜像启动一个普通 shell：

```bash
docker compose run --rm zephyr-sdk bash
```

### 在 Zephyr workspace 中使用镜像

把示例 compose 复制到你自己的 Zephyr 项目中，或者直接通过环境变量运行：

```bash
cp .env.example .env
cp docker-compose.example.yml compose.yaml
```

按你的项目修改 `.env`：

```text
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr
```

然后启动项目容器：

```bash
docker compose -f compose.yaml up -d
docker compose -f compose.yaml exec zephyr-sdk bash
```

在容器内验证环境：

```bash
echo $ZEPHYR_BASE
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_TOOLCHAIN_VARIANT
west --version
arm-zephyr-eabi-gcc --version
```

构建 Zephyr 示例：

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

镜像构建变量：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `BASE_IMAGE` | `docker.1ms.run/library/ubuntu:24.04` | 基础 Ubuntu 镜像。如果 Docker Hub 可访问，可以改成 `ubuntu:24.04`。 |
| `ZSDK_VERSION` | `1.0.1` | Zephyr SDK 版本。 |
| `SDK_TOOLCHAINS` | `all` | `setup.sh -t` 安装的 toolchains。只做 ARM 构建时可用 `arm-zephyr-eabi` 减小镜像体积。 |
| `HOSTTYPE` | `x86_64` | SDK 压缩包文件名里的主机架构。 |
| `IMAGE_NAME` | `zephyr-docker-sdk` | 输出镜像名。 |

`docker-compose.example.yml` 使用的项目运行变量：

| 变量 | 示例 | 说明 |
|---|---|---|
| `ZEPHYR_WORKSPACE` | `/path/to/zephyr-workspace` | 宿主机 Zephyr 工作区路径，挂载到容器内 `/workspace/zephyr-workspace`。 |
| `ZEPHYR_BASE` | `/workspace/zephyr-workspace/zephyr` | 容器内 Zephyr 仓库路径。 |
| `SYNC_ZEPHYR_REQUIREMENTS` | `1` | 设置为 `1` 时，容器启动时安装 `$ZEPHYR_BASE/scripts/requirements.txt`。 |

构建镜像示例：

```bash
BASE_IMAGE=ubuntu:24.04 \
ZSDK_VERSION=1.0.1 \
SDK_TOOLCHAINS=arm-zephyr-eabi \
docker compose build
```

项目运行示例：

```bash
ZEPHYR_WORKSPACE=/path/to/zephyr-workspace \
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr \
docker compose -f docker-compose.example.yml up -d
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
