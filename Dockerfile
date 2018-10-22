ARG TELEGRAF_VERSION=1.7.0
ARG GO_VERSION=1.10.1


FROM circleci/golang:${GO_VERSION} AS builder

ARG TELEGRAF_VERSION

RUN sudo apt-get update \
  && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
      autoconf \
      libtool \
      python \
      python-boto \
      rpm \
      ruby \
      ruby-dev \
  && sudo rm -rf /var/lib/apt/lists/* \
  && sudo gem install fpm

RUN go get -d github.com/influxdata/telegraf \
  && cd /go/src/github.com/influxdata/telegraf \
  && git checkout ${TELEGRAF_VERSION} \
  && ./scripts/build.py --package --platform=linux --arch=amd64


FROM telegraf:${TELEGRAF_VERSION}

RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y telegraf

RUN mkdir -p /tmp/telegraf-pkgs

COPY --from=builder \
  /go/src/github.com/influxdata/telegraf/build/*.deb \
  /tmp/telegraf-pkgs/

RUN dpkg --no-debsig -i /tmp/telegraf-pkgs/*.deb \
  && rm -rf /tmp/telegraf-pkgs
