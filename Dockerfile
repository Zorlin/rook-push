# Dockerfile

FROM alpine/k8s:1.27.13

RUN apk add --no-cache bash curl jq

COPY monitor.sh /monitor.sh

RUN chmod +x /monitor.sh

CMD ["/monitor.sh"]
