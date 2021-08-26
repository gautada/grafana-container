FROM alpine:3.14.1 as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

# ------------------------------------------------------------- BUILD GRAFANA
FROM config-alpine as config-grafana
ARG BRANCH=v0.0.0

RUN apk add --no-cache build-base git go yarn

RUN git config --global advice.detachedHead false

RUN mkdir /usr/lib/go/src/github.com
WORKDIR /usr/lib/go/src/github.com
RUN git clone --branch $BRANCH --depth 1 https://github.com/grafana/grafana.git
WORKDIR /usr/lib/go/src/github.com/grafana

RUN yarn install --pure-lockfile --no-progress
ENV NODE_ENV production
RUN yarn build

RUN go mod verify
RUN go run build.go build

# ----------------------------------------------------------- [STAGE] FINAL
FROM alpine:3.14.1

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone  /etc/timezone

COPY config.ini /etc/grafana/config.ini

RUN apk add --no-cache ca-certificates openssl musl-utils

ARG USER=grafana
RUN addgroup $USER \
 && adduser -D -s /bin/sh -G $USER $USER \
 && echo "$USER:$USER" | chpasswd

RUN mkdir -p /usr/share/grafana/provisioning/datasources \
             /usr/share/grafana/provisioning/plugins \
             /usr/share/grafana/provisioning/notifiers \
             /usr/share/grafana/provisioning/dashboards \
             /var/log/grafana \
             /var/lib/grafana/plugins
             
RUN chown $USER:$USER -R /usr/share/grafana /var/log/grafana /var/lib/grafana

USER $USER

WORKDIR /usr/share/grafana

COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/conf ./conf
COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/bin/*/grafana-server /usr/lib/go/src/github.com/grafana/bin/*/grafana-cli /usr/bin
COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/public ./public
COPY --from=config-grafana /usr/lib/go/src/github.com/grafana/tools ./tools



WORKDIR /
EXPOSE 3000
ENTRYPOINT ["/usr/bin/grafana-server"]
CMD ["--config=/etc/grafana/config.ini", "--homepath=/usr/share/grafana", "--packaging=container", "'$@'", "cfg:default.log.mode=console", "cfg:default.paths.data=/var/lib/grafana", "cfg:default.paths.logs=/var/log/grafana", "cfg:default.paths.plugins=/var/lib/grafana/plugins", "cfg:default.paths.provisioning=/usr/share/grafana/provisioning"]

