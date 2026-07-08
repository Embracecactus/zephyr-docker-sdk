# zephyr-docker-sdk

A lightweight Docker/Compose environment for building Zephyr projects with configurable Zephyr SDK versions.

This project is community-maintained and is not affiliated with the official Zephyr project Docker images.

## Features

- Ubuntu 24.04 based development image
- Zephyr SDK 1.0.1 by default
- Configurable SDK version and base image
- Optional local SDK archive cache for slow networks
- Docker Compose workflow with persistent ccache
- Automatic Python requirements sync from `$ZEPHYR_BASE/scripts/requirements.txt`

## Quick start

```bash
git clone https://github.com/Embracecactus/zephyr-docker-sdk.git
cd zephyr-docker-sdk
```

Set your Zephyr workspace path. For example, if your host workspace is `/home/lijian/project/zephyr/mcu-zephyr-project` and the Zephyr repository inside it is `zephyr-fork-bk7258`:

```bash
export ZEPHYR_WORKSPACE=/home/lijian/project/zephyr/mcu-zephyr-project
export ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr-fork-bk7258
```

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

## Local SDK archive cache

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

## Configuration

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
ZEPHYR_WORKSPACE=/home/lijian/project/zephyr/mcu-zephyr-project \
ZEPHYR_BASE=/workspace/zephyr-workspace/zephyr-fork-bk7258 \
docker compose build
```

## Common issues

### Docker Hub is not reachable

The default base image uses a Docker Hub mirror:

```text
docker.1ms.run/library/ubuntu:24.04
```

To use the official image instead:

```bash
BASE_IMAGE=ubuntu:24.04 docker compose build
```

### SDK archive is not a valid tar.xz

Check the file:

```bash
file cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
xz -t cache/zephyr-sdk-1.0.1_linux-x86_64_gnu.tar.xz
```

If it is invalid, remove it and download again with `wget -c`.

### CMake still finds an old SDK

Check inside the container:

```bash
echo $ZEPHYR_SDK_INSTALL_DIR
ls -d /opt/toolchains/zephyr-sdk-*
```

The default expected value is:

```text
/opt/toolchains/zephyr-sdk-1.0.1
```

## What is not included

This repository does not include:

- Zephyr SDK tarballs
- Docker image archives
- Zephyr source code
- Board-specific patches

It only contains Docker build and Compose files.
