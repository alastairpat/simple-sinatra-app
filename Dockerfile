FROM ruby:2.7

WORKDIR /application

COPY . /application

RUN bundle install

EXPOSE 9292

USER 1000

ENTRYPOINT ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
