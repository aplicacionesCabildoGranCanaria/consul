# syntax=docker/dockerfile:1

FROM ruby:3.3.11-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gnupg \
    imagemagick \
    libpq-dev \
    libyaml-dev \
    libxss1 \
    memcached \
    pkg-config \
    postgresql-client \
    sudo \
    unzip \
 && install -d -m 0755 /usr/share/keyrings \
 && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor --yes -o /usr/share/keyrings/google-chrome.gpg \
 && printf '%s\n' \
    'Types: deb' \
    'URIs: https://dl.google.com/linux/chrome/deb/' \
    'Suites: stable' \
    'Components: main' \
    'Architectures: amd64' \
    'Signed-By: /usr/share/keyrings/google-chrome.gpg' \
    > /etc/apt/sources.list.d/google-chrome.sources \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && CHROME_VERSION="$(google-chrome-stable --product-version)" \
 && echo "Installing ChromeDriver ${CHROME_VERSION}" \
 && curl -fsSL \
    "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" \
    -o /tmp/chromedriver.zip \
 && unzip -q /tmp/chromedriver.zip -d /tmp/chromedriver \
 && install -m 0755 \
    /tmp/chromedriver/chromedriver-linux64/chromedriver \
    /usr/local/bin/chromedriver \
 && google-chrome-stable --version \
 && chromedriver --version \
 && rm -rf \
    /tmp/chromedriver \
    /tmp/chromedriver.zip \
    /var/lib/apt/lists/*

RUN adduser --shell /bin/bash --disabled-password --gecos "" consul \
 && adduser consul sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bundle/bin:/usr/local/node/bin"' > /etc/sudoers.d/secure_path \
 && chmod 0440 /etc/sudoers.d/secure_path

ENV RAILS_ROOT=/var/www/consul
ENV BUNDLE_PATH=/usr/local/bundle
ENV PATH=/usr/local/node/bin:$PATH

RUN mkdir -p $RAILS_ROOT/tmp/pids

WORKDIR $RAILS_ROOT

COPY .node-version ./

RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ \
 && /tmp/node-build-master/bin/node-build "$(cat .node-version)" /usr/local/node \
 && rm -rf /tmp/node-build-master

COPY .ruby-version ./
COPY Gemfile* ./

RUN --mount=type=cache,target=/usr/local/bundle/cache \
    bundle install --jobs 1 --retry 2

COPY package* ./
RUN npm install

COPY . .

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]