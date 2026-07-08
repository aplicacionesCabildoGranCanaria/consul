FROM ruby:3.3.11-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    imagemagick \
    libpq-dev \
    libxss1 \
    memcached \
    pkg-config \
    postgresql-client \
    sudo \
    unzip \
    chromium \
    chromium-driver \
 && rm -rf /var/lib/apt/lists/*

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
RUN bundle install

COPY package* ./
RUN npm install

COPY . .

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]