FROM golang:1.23.4-bullseye AS development

LABEL maintainer="Jean Bonilha <jeanbonilha.webdev@gmail.com>"

ARG HOME_USER=/home/go
ARG ORACLE_INSTANT_CLIENT_ARCH=x86_64
ARG ORACLE_INSTANT_CLIENT_MAJOR=18
ARG ORACLE_INSTANT_CLIENT_MINOR=3
ARG ORACLE_INSTANT_CLIENT_MIRROR=https://github.com/the-paulus/oracle-instantclient/raw/master/
ARG ORACLE_INSTANT_CLIENT_PATH=/opt/oracle/instantclient_

ENV DEBIAN_FRONTEND noninteractive
ENV GOENV="development"
ENV ORACLE_INSTANT_CLIENT_VERSION="${ORACLE_INSTANT_CLIENT_MAJOR}_${ORACLE_INSTANT_CLIENT_MINOR}"
ENV LD_LIBRARY_PATH="${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}"
ENV OCI_HOME="${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}"
ENV OCI_INCLUDE_DIR="${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/sdk/include"
ENV OCI_LIB_DIR="${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}"
ENV OCI_VERSION=${ORACLE_INSTANT_CLIENT_MAJOR}

ENV NODE_VERSION v22.12.0
ENV NVM_DIR ${HOME_USER}/.nvm
ENV NPM_FETCH_RETRIES 2
ENV NPM_FETCH_RETRY_FACTOR 10
ENV NPM_FETCH_RETRY_MINTIMEOUT 10000
ENV NPM_FETCH_RETRY_MAXTIMEOUT 60000

ENV SOURCE_CODE ${HOME_USER}/sourcecode

RUN go install golang.org/x/tools/cmd/godoc@v0.5.0
RUN go install github.com/kyleconroy/sqlc/cmd/sqlc@v1.18.0
RUN go install github.com/wailsapp/wails/v2/cmd/wails@v2.8.1
RUN go install github.com/air-verse/air@v1.52.3

RUN set -xe; \
    apt-get update && \
    apt-get upgrade -yqq && \
    apt-get install -yqq \
    apt-utils \
    gnupg2 \
    git \
    libzip-dev zip unzip \
    default-mysql-client \
    inetutils-ping \
    wget \
    libaio-dev \
    freetds-dev \
    sudo \
    bash-completion \
    curl \
    make \
    ncurses-dev \
    build-essential \
    tree \
    nano \
    tmux \
    tmuxinator \
    xclip \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    libssl-dev \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    nsis \
    ripgrep \
    fontconfig \
    gcc \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/fonts/truetype/nerd-fonts \
    && wget -O /tmp/nerd-fonts.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FontPatcher.zip \
    && unzip /tmp/nerd-fonts.zip -d /usr/share/fonts/truetype/nerd-fonts \
    && rm /tmp/nerd-fonts.zip \
    && fc-cache -fv

RUN mkdir /opt/oracle \
    && cd /opt/oracle \
    && wget ${ORACLE_INSTANT_CLIENT_MIRROR}instantclient-basic-linux.${ORACLE_INSTANT_CLIENT_ARCH}-${ORACLE_INSTANT_CLIENT_VERSION}.zip \
    && wget ${ORACLE_INSTANT_CLIENT_MIRROR}instantclient-sdk-linux.${ORACLE_INSTANT_CLIENT_ARCH}-${ORACLE_INSTANT_CLIENT_VERSION}.zip

RUN unzip /opt/oracle/instantclient-basic-linux.${ORACLE_INSTANT_CLIENT_ARCH}-${ORACLE_INSTANT_CLIENT_VERSION}.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.${ORACLE_INSTANT_CLIENT_ARCH}-${ORACLE_INSTANT_CLIENT_VERSION}.zip -d /opt/oracle \
    && if [ ${OCI_VERSION} -lt 18 ] ; then ln -s ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libclntsh.so.${ORACLE_INSTANT_CLIENT_MAJOR}.${ORACLE_INSTANT_CLIENT_MINOR} ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libclntsh.so ; fi\
    && if [ ${OCI_VERSION} -lt 18 ] ; then ln -s ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libclntshcore.so.${ORACLE_INSTANT_CLIENT_MAJOR}.${ORACLE_INSTANT_CLIENT_MINOR} ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libclntshcore.so ; fi \
    && if [ ${OCI_VERSION} -lt 18 ] ; then ln -s ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libocci.so.${ORACLE_INSTANT_CLIENT_MAJOR}.${ORACLE_INSTANT_CLIENT_MINOR} ${ORACLE_INSTANT_CLIENT_PATH}${ORACLE_INSTANT_CLIENT_VERSION}/libocci.so ; fi \
    && rm -rf /opt/oracle/*.zip

RUN curl -LO https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz && \
    tar -C /opt -xzf nvim-linux64.tar.gz && \
    rm nvim-linux64.tar.gz

RUN useradd -ms /bin/bash go && echo "go:secret" | chpasswd && adduser go sudo

RUN rm -rf /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Manaus /etc/localtime

USER go

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use ${NODE_VERSION} \
    && nvm alias ${NODE_VERSION} \
    && npm config set fetch-retries ${NPM_FETCH_RETRIES} \
    && npm config set fetch-retry-factor ${NPM_FETCH_RETRY_FACTOR} \
    && npm config set fetch-retry-mintimeout ${NPM_FETCH_RETRY_MINTIMEOUT} \
    && npm config set fetch-retry-maxtimeout ${NPM_FETCH_RETRY_MAXTIMEOUT} \
    && npm install -g yarn \
    && npm install -g npm \
    && git clone --depth=1 https://github.com/i3onilha/nvim $HOME/.config/nvim \
    && /opt/nvim-linux64/bin/nvim -c 'MasonInstallAll' -c 'q' \
    && /opt/nvim-linux64/bin/nvim -c 'GoUpdateBinaries' -c 'q'

RUN git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && $HOME/.fzf/install

RUN git clone --bare -b godevenv https://github.com/i3onilha/.dotfiles.git $HOME/.dotfiles && \
    git clone https://github.com/i3onilha/.tmux.git $HOME/.tmux && \
    ln -sf .tmux/.tmux.conf $HOME && \
    cp $HOME/.tmux/.tmux.conf.local $HOME && \
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no && \
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME reset HEAD . && \
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout -- .

RUN export PATH="$HOME/.nvm/versions/node/$NODE_VERSION/bin:$PATH"

WORKDIR $SOURCE_CODE

COPY . .

FROM golang:1.23.4-bullseye AS builder

WORKDIR /home/go/sourcecode

COPY go.* .

RUN go mod download

COPY . .

RUN go build -o service ./cmd/server/server.go

FROM oraclelinux:7-slim AS production

ENV SOURCE_CODE /app

LABEL "provider"="Oracle"                                               \
    "issues"="https://github.com/oracle/docker-images/issues"

RUN rm -rf /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Manaus /etc/localtime

ARG release=19
ARG update=8

ENV PATH=$PATH:/usr/lib/oracle/${release}.${update}/client64/bin

RUN yum -y install oracle-release-el7 openssh git cronie && \
    yum -y install oracle-instantclient${release}.${update}-basic oracle-instantclient${release}.${update}-devel oracle-instantclient${release}.${update}-sqlplus && \
    rm -rf /var/cache/yum

WORKDIR /app

COPY --from=builder /home/go/sourcecode/service /app/service

COPY --from=builder /home/go/sourcecode/.env-prod /app/.env

CMD ["/app/service"]
