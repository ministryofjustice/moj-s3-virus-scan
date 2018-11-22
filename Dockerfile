FROM ruby:2.5

WORKDIR /usr/src/app

EXPOSE 4567

RUN apt-get update && apt-get install -y less \
                                         clamav \
                                         clamav-daemon \
                                         clamav-freshclam && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle config --global frozen 1 \
    && bundle install ${development:+--with="test development"}

COPY . .

ENTRYPOINT ["./run.sh"]
