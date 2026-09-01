FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------
# Minimal OS dependencies
# ---------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    openssh-server \
    build-essential \
    pkg-config \
    libssl-dev \
    neovim \
    tmux \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Create unprivileged user
# ---------------------------------------------------------

RUN useradd \
    --create-home \
    --shell /bin/bash \
    --uid 1000 \
    kat

RUN mkdir -p \
    /workspace \
    /home/kat/.ssh \
    /run/sshd \
    && chown -R kat:kat /workspace /home/kat

# ---------------------------------------------------------
# SSH configuration
# ---------------------------------------------------------

RUN ssh-keygen -A \
    && sed -i \
        -e 's/^#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        /etc/ssh/sshd_config

# ---------------------------------------------------------
# tmux configuration
# ---------------------------------------------------------

COPY .tmux.conf /home/kat/.tmux.conf

RUN chown kat:kat /home/kat/.tmux.conf \
    && chmod 600 /home/kat/.tmux.conf

# ---------------------------------------------------------
# uv
# Official Astral installer
# ---------------------------------------------------------

USER kat

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/home/kat/.local/bin:${PATH}"

# ---------------------------------------------------------
# Python
# Managed by uv
# ---------------------------------------------------------

RUN uv python install 3.12
RUN mkdir -p /home/kat/pyhome \
    && uv venv /home/kat/pyhome/algox --python 3.12

RUN printf '%s\n' \
'export PATH="/home/kat/.local/bin:/home/kat/.cargo/bin:/usr/local/go/bin:/home/kat/go/bin:$PATH"' \
'a() {' \
'    source /home/kat/pyhome/algox/bin/activate' \
'}' \
>> /home/kat/.bashrc

# ---------------------------------------------------------
# Rust
# Official rustup
# ---------------------------------------------------------

RUN curl --proto '=https' \
    --tlsv1.2 \
    -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path

ENV PATH="/home/kat/.cargo/bin:${PATH}"

# ---------------------------------------------------------
# Go
# Official Go distribution
# ---------------------------------------------------------

USER root

ARG GO_VERSION=1.27.0

RUN curl -fsSL \
    "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -f /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:/home/kat/go/bin:${PATH}"

# ---------------------------------------------------------
# Node.js
# Official Node.js distribution
# ---------------------------------------------------------

ARG NODE_VERSION=26.0.0

RUN curl -fsSL \
    "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    -o /tmp/node.tar.xz \
    && mkdir -p /usr/local/lib/nodejs \
    && tar -xJf /tmp/node.tar.xz \
        -C /usr/local/lib/nodejs \
    && ln -s \
        /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/node \
        /usr/local/bin/node \
    && ln -s \
        /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/npm \
        /usr/local/bin/npm \
    && ln -s \
        /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/npx \
        /usr/local/bin/npx \
    && rm -f /tmp/node.tar.xz

# ---------------------------------------------------------
# Runtime
# ---------------------------------------------------------

RUN mkdir -p /run/sshd \
    && chmod 0755 /run/sshd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

EXPOSE 69

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
