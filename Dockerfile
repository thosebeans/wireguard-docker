FROM alpine:3.14.2

WORKDIR /

RUN apk add --no-cache wireguard-tools
RUN apk add --no-cache sipcalc

ADD run.sh /run.sh

CMD /run.sh

ENV I_CREATE=1
ENV I_REUSE=0
ENV I_NODESTROY=0
