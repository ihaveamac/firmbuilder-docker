################################################
FROM devkitpro/devkitarm AS builder-base

# preserve package cache on a volume
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,target=/var/lib/apt,sharing=locked \
	set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends build-essential

################################################
FROM builder-base AS armips-builder

RUN set -eux; \
	git clone --depth 1 --recursive https://github.com/Kingcom/armips.git; \
	cd armips; \
	mkdir build && cd build; \
	cmake -DCMAKE_BUILD_TYPE=Release ..; \
	cmake --build .

################################################
FROM builder-base AS makerom-builder

RUN set -eux; \
	git clone --depth 1 https://github.com/3DSGuy/Project_CTR.git; \
	cd Project_CTR/makerom; \
	make -j4 deps; \
	make -j4;

################################################
FROM builder-base

ENV HOME /home/builder
RUN useradd -m -d $HOME -s /bin/bash -u 1000 builder

RUN set -eux; \
	git clone --depth 1 https://github.com/devkitPro/libctru.git; \
	cd libctru/libctru; \
	make -j4 && make install; \
	cd ../..; \
	rm -rf libctru;

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,target=/var/lib/apt,sharing=locked \
	set -eux; \
	apt-get update; \
	# pkg-resources is required for the firmtool shortcut to be used (firmtool itself doesn't depend on it) \
	# pip doesn't detect the system version of python3-pycryptodome so i decided to just use the one from pypi \
	apt-get install -y --no-install-recommends python3-pkg-resources p7zip; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-dev; \
	python3 -m pip install --no-cache-dir --no-compile https://github.com/TuxSH/firmtool/archive/refs/heads/master.zip; \
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;

COPY --from=armips-builder /armips/build/armips /usr/local/bin/armips
COPY --from=makerom-builder /Project_CTR/makerom/bin/makerom /usr/local/bin/makerom

USER builder

WORKDIR /host
