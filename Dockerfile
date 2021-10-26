FROM debian:bullseye-slim AS android-sdk

RUN set -eux; \
    sed -i 's/\(deb\|security\)\.debian\.org/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends -o 'Acquire::Retries=3' \
       # jdk
        openjdk-11-jdk-headless \
        # misc
        git \
        unzip \
        wget \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    groupadd --gid 1000 pilot; \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash pilot

ENV ANDROID_SDK_ROOT=/home/pilot/android-sdk
ENV PATH="$ANDROID_SDK_ROOT/cmdline-tools/bin:$PATH"
ENV PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"

USER pilot

RUN set -eux; \
    wget -q -O /tmp/android-sdk-command-line-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip; \
    unzip -d /tmp /tmp/android-sdk-command-line-tools.zip; \
    mkdir -p $ANDROID_SDK_ROOT; \
    mv /tmp/cmdline-tools $ANDROID_SDK_ROOT; \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses

FROM android-sdk AS scrcpy-builder

USER root

RUN set -eux; \
    sed -i 's/\(deb\|security\)\.debian\.org/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends -o 'Acquire::Retries=3' \
        # build tools
        gcc \
        meson \
        ninja-build \
        pkg-config \
        # deps
        libavcodec-dev \
        libavdevice-dev \
        libavformat-dev \
        libavutil-dev \
        libsdl2-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

USER pilot

RUN set -eux; \
    git clone https://github.com/Genymobile/scrcpy.git --depth=1 --branch=v1.19 /home/pilot/scrcpy; \
    cd /home/pilot/scrcpy; \
    meson x --buildtype release --strip -Db_lto=true; \
    cd x; \
    ninja

FROM android-sdk

USER root

RUN set -eux; \
    sed -i 's/\(deb\|security\)\.debian\.org/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends -o 'Acquire::Retries=3' \
        ffmpeg \
        libsdl2-2.0-0 \
    ; \
    rm -rf /var/lib/apt/lists/*

COPY --from=scrcpy-builder /home/pilot/scrcpy/x/server/scrcpy-server /usr/local/share/scrcpy/
COPY --from=scrcpy-builder /home/pilot/scrcpy/x/app/scrcpy /usr/local/bin/

USER pilot

RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT --install "platform-tools"
