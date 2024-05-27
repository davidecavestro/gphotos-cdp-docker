FROM golang:1.20.5-bullseye AS build
ARG COMMIT=53afb72ae12955edaac20533d9fcfda12b630336
# RUN apt-get update && apt-get install -y \
#   git \
#   wget \
#   build-base shadow

ENV GO111MODULE=on
RUN go install github.com/perkeep/gphotos-cdp@${COMMIT}


FROM chromedp/headless-shell:latest

RUN apt-get update && apt-get install -y \
      exiftool \
      curl \
      && rm -rf /var/lib/apt/lists/*

COPY --from=build /go/bin/gphotos-cdp /usr/local/bin/
COPY save.sh /usr/local/bin/

VOLUME /tmp/gphotos-cdp
VOLUME /download

ENTRYPOINT ["/usr/local/bin/gphotos-cdp", "-v", "-dev", "-headless", "-dldir", "/download", "-run", "/usr/local/bin/save.sh" ]
