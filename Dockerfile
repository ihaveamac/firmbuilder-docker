FROM devkitpro/devkitarm AS armips-builder

# preserve package cache on a volume
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,target=/var/lib/apt,sharing=locked \
	set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends build-essential

RUN set -eux; \
	git clone --recursive https://github.com/Kingcom/armips.git; \
	cd armips; \
	mkdir build && cd build; \
	cmake -DCMAKE_BUILD_TYPE=Release ..; \
	cmake --build .

FROM devkitpro/devkitarm

# preserve package cache on a volume
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

ENV HOME /home/builder
RUN useradd -m -d $HOME -s /bin/bash -u 1000 builder

ENV MAKEROM_VERSION v0.18.3

RUN set -eux; \
	wget -O makerom.zip https://github.com/3DSGuy/Project_CTR/releases/download/makerom-${MAKEROM_VERSION}/makerom-${MAKEROM_VERSION}-ubuntu_x86_64.zip; \
	unzip makerom.zip; \
	chmod +x makerom; \
	mv makerom /usr/local/bin/makerom; \
	rm makerom.zip

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,target=/var/lib/apt,sharing=locked \
	set -eux; \
	apt-get update; \
	# pkg-resources is required for the firmtool shortcut to be used (firmtool itself doesn't depend on it) \
	# pip doesn't detect the system version of python3-pycryptodome so i decided to just use the one from pypi \
	apt-get install -y --no-install-recommends python3-pkg-resources p7zip; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-dev build-essential; \
	python3 -m pip install --no-cache-dir --no-compile https://github.com/TuxSH/firmtool/archive/refs/heads/master.zip; \
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;

COPY --from=armips-builder /armips/build/armips /usr/local/bin/armips

USER builder

WORKDIR /host
