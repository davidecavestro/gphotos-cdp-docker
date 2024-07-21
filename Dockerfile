FROM golang:1.20.5-bullseye AS build

ENV GO111MODULE=on
RUN git clone https://github.com/davidecavestro/gphotos-cdp.git /ws
WORKDIR /ws
RUN go build

FROM chromedp/headless-shell:latest

LABEL org.opencontainers.image.source "https://github.com/davidecavestro/docker-gphotos-cdp"
LABEL org.opencontainers.image.description "Download photos and videos from your account without loosing geo-location attributes"
LABEL org.opencontainers.image.licenses "BSD 3-Clause License"

RUN apt-get update && apt-get install -y \
      exiftool \
      curl \
      rsync \
      locales \
      tree \
      file \
      jq \
      ffmpeg \
      && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8   

# copy tool binary
COPY --from=build /ws/gphotos-cdp /usr/local/bin/
# copy default script
COPY save.sh /usr/local/bin/

VOLUME /tmp/gphotos-cdp
VOLUME /download

ENTRYPOINT ["/usr/local/bin/gphotos-cdp", "-v", "-dev", "-headless", "-dldir", "/download", "-run", "/usr/local/bin/save.sh" ]
