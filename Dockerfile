FROM ruby:3.2.6-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install essential Linux packages
RUN apt-get update -qq \
 && apt-get install -y \
    build-essential \
    cmake \
    imagemagick \
    libappindicator1 \
    libpq-dev \
    libxss1 \
    memcached \
    nodejs \
    pkg-config \
    postgresql-client \
    shared-mime-info \
    sudo \
    unzip \
    chromium

# Crear usuario seguro
RUN adduser --shell /bin/bash --disabled-password --gecos "" consul && \
    adduser consul sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Definir el directorio de la aplicación
ENV RAILS_ROOT=/var/www/consul
ENV BUNDLE_PATH=/usr/local/bundle
WORKDIR $RAILS_ROOT

# Asegurar que el usuario `consul` tiene permisos correctos en /usr/local/bundle
RUN chown -R consul:consul /usr/local/bundle /var/www/consul


# Instalar Node.js
COPY .node-version ./
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build `cat .node-version` /usr/local/node && \
    rm -rf /tmp/node-build-master

# Copiar archivos esenciales antes de instalar gems
COPY .ruby-version ./
COPY Gemfile* ./

# Delete Gemfile.lock if exists
RUN rm -f Gemfile.lock

# Include Gemfile_custom
COPY Gemfile_custom Gemfile_custom

RUN gem install bundler -v 2.4.22
RUN bundle install

# Instalar dependencias de Node.js
COPY package* ./
RUN npm install

# Copiar el resto de la aplicación
COPY . .

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]