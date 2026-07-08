# Lightweight Zephyr SDK Docker image

ARG BASE_IMAGE=docker.1ms.run/library/ubuntu:24.04
FROM ${BASE_IMAGE}

ARG USERNAME=zephyr
ARG USER_UID=1000
ARG USER_GID=1000
ARG HOSTTYPE=x86_64
ARG ZSDK_VERSION=1.0.1
ARG SDK_TOOLCHAINS=all
ARG PYTHON_VENV_PATH=/opt/python/venv
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll"
ARG UBUNTU_MIRROR_ARCHIVE=mirrors.tuna.tsinghua.edu.cn/ubuntu
ARG UBUNTU_MIRROR_SECURITY=mirrors.tuna.tsinghua.edu.cn/ubuntu
ARG UBUNTU_MIRROR_PORTS=mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV ZSDK_VERSION=${ZSDK_VERSION}
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
ENV ZEPHYR_BASE=
ENV PYTHON_VENV_PATH=${PYTHON_VENV_PATH}
ENV PATH=${PYTHON_VENV_PATH}/bin:/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/bin:/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/arm-zephyr-eabi/bin:${PATH}

RUN <<EOF
	pushd /etc/apt/sources.list.d
	cp ubuntu.sources ubuntu.sources.bak
	sed -i "s#archive.ubuntu.com/ubuntu#${UBUNTU_MIRROR_ARCHIVE}#" ubuntu.sources
	sed -i "s#security.ubuntu.com/ubuntu#${UBUNTU_MIRROR_SECURITY}#" ubuntu.sources
	sed -i "s#ports.ubuntu.com/ubuntu-ports#${UBUNTU_MIRROR_PORTS}#" ubuntu.sources
	popd

	apt-get -y update
	apt-get -y upgrade
	apt-get install --no-install-recommends -y \
		bash-completion \
		bison \
		build-essential \
		ca-certificates \
		ccache \
		cmake \
		device-tree-compiler \
		dfu-util \
		diffstat \
		dos2unix \
		file \
		flex \
		gawk \
		gcc \
		g++ \
		gdb \
		git \
		gnupg \
		gperf \
		graphviz \
		help2man \
		iproute2 \
		libncurses5-dev \
		libssl-dev \
		locales \
		make \
		ninja-build \
		pkg-config \
		python-is-python3 \
		python3 \
		python3-dev \
		python3-pip \
		python3-setuptools \
		python3-venv \
		rsync \
		srecord \
		sudo \
		texinfo \
		unzip \
		vim \
		wget \
		xz-utils

	apt-get autoremove --purge -y
	apt-get clean -y
	rm -rf /var/lib/apt/lists/*

	pushd /etc/apt/sources.list.d
	mv -f ubuntu.sources.bak ubuntu.sources
	popd
EOF

RUN locale-gen en_US.UTF-8

RUN <<EOF
	mkdir -p ${PYTHON_VENV_PATH}
	python3 -m venv ${PYTHON_VENV_PATH}
	source ${PYTHON_VENV_PATH}/bin/activate
	python3 -m pip install --upgrade pip setuptools wheel
	python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
	python3 -m pip install west pyelftools pyyaml packaging canopen anytree junitparser jsonschema
EOF

COPY cache/ /tmp/zephyr-sdk-cache/

RUN <<EOF
	mkdir -p /opt/toolchains
	cd /opt/toolchains
	SDK_ARCHIVE="zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}_gnu.tar.xz"
	if [ -f "/tmp/zephyr-sdk-cache/${SDK_ARCHIVE}" ]; then
		cp "/tmp/zephyr-sdk-cache/${SDK_ARCHIVE}" .
	else
		wget ${WGET_ARGS} "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/${SDK_ARCHIVE}"
	fi
	tar xf "${SDK_ARCHIVE}"
	"/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/setup.sh" -t ${SDK_TOOLCHAINS} -h -c
	rm "${SDK_ARCHIVE}"
EOF

RUN <<EOF
	if getent group ${USER_GID} >/dev/null; then
		GROUP_NAME=$(getent group ${USER_GID} | cut -d: -f1)
	else
		groupadd --gid ${USER_GID} ${USERNAME}
		GROUP_NAME=${USERNAME}
	fi

	if id -u ${USER_UID} >/dev/null 2>&1; then
		EXISTING_USER=$(getent passwd ${USER_UID} | cut -d: -f1)
		usermod -l ${USERNAME} -d /home/${USERNAME} -m ${EXISTING_USER}
	else
		useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash ${USERNAME}
	fi

	usermod -aG sudo ${USERNAME}
	echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USERNAME}
	chmod 0440 /etc/sudoers.d/${USERNAME}
	mkdir -p /workspace /home/${USERNAME}/.ccache
	chown -R ${USERNAME}:${USER_GID} /workspace /home/${USERNAME} ${PYTHON_VENV_PATH}
EOF

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
USER ${USERNAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
