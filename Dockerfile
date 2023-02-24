FROM ruby:2.7.1-alpine

ARG RUBY_ROOT=/bot
ARG PACKAGES="vim openssl-dev postgresql-dev build-base curl yarn less tzdata git postgresql-client bash screen"

RUN apk update \
  && apk upgrade \
  && apk add --update --no-cache $PACKAGES

RUN gem install bundler:2.1.4

RUN mkdir $RUBY_ROOT
WORKDIR $RUBY_ROOT

COPY Gemfile*  ./
RUN bundle install --jobs 5

ADD . $RUBY_ROOT
ENV PATH=$RUBY_ROOT/bin:${PATH}

EXPOSE 3333
# CMD exe/app
