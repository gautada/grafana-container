# ------------------------------------------------------------- [STAGE] INIT
ARG ALPINE_TAG=0.0.0

FROM alpine:$ALPINE_TAG as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

# ------------------------------------------------------------- [STAGE] BUILD
FROM alpine:$ALPINE_TAG as config-grafana

ARG BRANCH=v0.0.0

RUN apk add --no-cache build-base git go yarn
RUN git config --global advice.detachedHead false

RUN mkdir /usr/lib/go/src/github.com
WORKDIR /usr/lib/go/src/github.com
RUN git clone --branch $BRANCH --depth 1 https://github.com/grafana/grafana.git
WORKDIR /usr/lib/go/src/github.com/grafana

# RUN yarn --help
# RUN yarn help install
# RUN yarn install --help

# https://yarnpkg.com/en/docs/cli/
# RUN yarn config

RUN yarn install --verbose --pure-lockfile --har --no-progress
ENV NODE_ENV production
RUN yarn build

RUN go mod verify
RUN go run build.go build

# ----------------------------------------------------------- [STAGE] FINAL
FROM alpine:$ALPINE_TAG

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone  /etc/timezone

EXPOSE 3000

COPY config.ini /etc/grafana/config.ini

RUN apk add --no-cache ca-certificates openssl musl-utils

RUN mkdir -p /var/log/grafana \
             /opt/grafana-data

RUN chmod 777 /opt/grafana-data

COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/bin/*/grafana-server /usr/lib/go/src/github.com/grafana/bin/*/grafana-cli /usr/bin

ARG USER=grafana
RUN addgroup $USER \
 && adduser -D -s /bin/sh -G $USER $USER \
 && echo "$USER:$USER" | chpasswd
             
RUN chown $USER:$USER -R /var/log/grafana

USER $USER

WORKDIR /home/grafana

RUN ln -s /opt/grafana-data /home/grafana/lib

RUN mkdir -p /home/grafana/lib/provisioning/datasources \
             /home/grafana/lib/provisioning/plugins \
             /home/grafana/lib/provisioning/notifiers \
             /home/grafana/lib/provisioning/dashboards \
             /home/grafana/lib/plugins
             


COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/conf ./conf
COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/public ./public
COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/tools ./tools


ENTRYPOINT ["/usr/bin/grafana-server"]
CMD ["--config=/etc/grafana/config.ini", "--homepath=/home/grafana", "--packaging=container", "'$@'", "cfg:default.log.mode=console", "cfg:default.paths.data=/var/lib/grafana", "cfg:default.paths.logs=/var/log/grafana", "cfg:default.paths.plugins=/home/grafana/lib/plugins", "cfg:default.paths.provisioning=/home/grafana/lib/provisioning"]

