# Original docker image must use from here: https://github.com/AlexanderDronkin/devops_oraclelinux
FROM oraclelinux:8.7

ARG TIMEZONE=Europe/Moscow
ARG USER_GID=1000
ARG USER_UID=1000

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p /home/developer
WORKDIR /home/developer

# Timezone
RUN ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && chmod -R 0600 /root/.ssh

# Prerequisites
RUN dnf update --assumeyes
RUN dnf --assumeyes --enablerepo=ol8_codeready_builder install ninja-build
RUN dnf install --assumeyes openssh java-17-openjdk curl file git unzip which xz zip mesa-libGLU clang cmake pkg-config gtk3-devel

# Prepare Android directories and system variables
RUN mkdir -p Android/sdk
ENV ANDROID_SDK_ROOT /home/developer/Android/sdk
RUN mkdir -p .android && touch .android/repositories.cfg

# Android SDK
COPY ./files/cmdline-tools Android/sdk/cmdline-tools/latest
RUN cd Android/sdk/cmdline-tools/latest/bin && (while sleep 3; do echo "y"; done) | ./sdkmanager --licenses || true
RUN cd Android/sdk/cmdline-tools/latest/bin && ./sdkmanager "build-tools;34.0.0" "patcher;v4" "platform-tools" "platforms;android-34" "sources;android-34"
ENV PATH "$PATH:/home/developer/Android/sdk/platform-tools"

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/developer/flutter/bin"

# Google Chrome
COPY ./files/google-chrome-stable.rpm /home/developer/google-chrome-stable.rpm
RUN dnf install --assumeyes /home/developer/google-chrome-stable.rpm && rm -f /home/developer/google-chrome-stable.rpm   

RUN git config --global --add safe.directory /home/developer/app \
    && git config --global --add safe.directory /home/developer/flutter

RUN flutter channel stable \
    && flutter doctor

RUN dnf clean all

RUN mkdir -p app
WORKDIR /home/developer/app