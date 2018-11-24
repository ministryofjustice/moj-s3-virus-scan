FROM ruby:2.5-slim

WORKDIR /usr/src/app

EXPOSE 4567

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
               clamav \
               clamav-daemon \
               clamav-freshclam \
               clamdscan \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN build_deps=' \
      gcc \
      make \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $build_deps \
    && rm -rf /var/lib/apt/lists/* \
    && bundle config --global frozen 1 \
    && bundle install \
    && apt-get -y --auto-remove purge $build_deps

COPY . .

ENTRYPOINT ["./run.sh"]
