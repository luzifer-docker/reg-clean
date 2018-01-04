FROM python:3-alpine

LABEL maintainer Knut Ahlers <knut@ahlers.me>

RUN set -ex \
 && apk add --update bash curl jq \
 && pip install awscli

ADD regclean.sh /usr/local/bin/regclean.sh

ENTRYPOINT ["/usr/local/bin/regclean.sh"]
