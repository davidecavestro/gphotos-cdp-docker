# docker-gphotos-cdp

A container image based on [gphotos-cdp](https://github.com/perkeep/gphotos-cdp) and [chromedp/headless-shell](https://github.com/chromedp/docker-headless-shell) to download photos and videos from your account without loosing geo-location attributes.

By default each downloaded file is passed to _[save.sh](save.sh)_ which detects its type, extracts the _creation date/time_ and moves it to a `year/year-month` subfolder within a _target_ directory.
Default logic can be easily overridden mounting a script with any other custom logic.


## Example usage

### Create a browser profile

Launch the browser with a profile from scratch into an empty folder, then complete the authentication.
```bash
google-chrome \
  --user-data-dir=/path/to/gphotos/profile_family \
  --no-first-run  \
  --password-store=basic \
  --use-mock-keychain \
  https://photos.google.com/
```
Close the browser: now the folder you chose has the credentials needed to open a headless browser and access your photos.


### Configure docker compose

Launch the container mounting the profile folder and the directory where
you want to download your stuff

```compose.yml
---
version: "3"

services:
  gphoto:
    image: davidecavestro/gphotos-cdp:latest
#    command: -start https://photos.google.com/photo/abcd1234...
    working_dir: /download
    volumes:
    - /etc/localtime:/etc/localtime
    - /path/to/gphotos/profile_family:/tmp/gphotos-cdp
    - /Volume1/Photos/data_gphotos:/dest
    environment:
    - DEST_DIR=/dest
#    - TZ=Europe/Rome
#    - IGNORE_REGEX=(^(Screenshot_|VID-).*)|(.*(MV-PANO|COLLAGE|-ANIMATION|-EFFECTS)\..*)
    restart: no

```

### Schedule from your host crontab

Optionally configure cron, i.e. for me running `crontab -l` reveals:
```bash
0 20 * * * docker compose --project-name gphotos_family -f /path/to/gphotos/compose.yml up -d
```

### Schedule with chadburn

I currently prefer scheduling from [chadburn](https://github.com/PremoWeb/chadburn) container

```compose.yml
---
version: "3"

services:
  chadburn:
    image: premoweb/chadburn:latest
    depends_on:
    - gphoto
    command: daemon
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  gphoto:
    image: davidecavestro/gphotos-cdp:latest
#    command: -start https://photos.google.com/photo/abcd1234...
    working_dir: /download
    volumes:
    - /etc/localtime:/etc/localtime
    - /path/to/gphotos/profile_family:/tmp/gphotos-cdp
    - /Volume1/Photos/data_gphotos:/dest
    environment:
    - DEST_DIR=/dest
#    - TZ=Europe/Rome
#    - IGNORE_REGEX=(^(Screenshot_|VID-).*)|(.*(MV-PANO|COLLAGE|-ANIMATION|-EFFECTS)\..*)
    restart: no
    entrypoint: ["sleep", "99999d"]
    labels:
      chadburn.enabled: "true"
      chadburn.job-exec.synccron.schedule: "@hourly"
      chadburn.job-exec.synccron.command: "date && /usr/local/bin/gphotos-cdp -v -dev -headless -dldir /download -run /usr/local/bin/save.sh"
      chadburn.job-exec.synccron.no-overlap: "true"

```

## How to build locally

The Dockerfile currently builds gphotos-cdp from a locally cloned repo
(a fork with some customizations) but avoids actually cloning it, while
the automated build on GH has a dedicated clone step.

Locally I simply symlink the repo with `ln -s ../gphotos-cdp repo`
and resolve the link using tar `tar -ch . | docker build --progress plain --no-cache -t foo -`

Then I test it with

```bash
docker run \
  --rm -it -u $(id -u):$(id -g) \
  -e DEST_DIR=/dest \
  -v $(pwd)/profile_famiglia:/tmp/gphotos-cdp/ \
  -v $(pwd)/download:/download \
  -v $(pwd)/dest:/dest \
  -w /download \
  --entrypoint /usr/local/bin/gphotos-cdp \
  --cap-add=SYS_ADMIN foo \
  -v -dev -headless -dldir /download -dltimeout 3 -run /usr/local/bin/save.sh
```

## Image project home

https://github.com/davidecavestro/gphotos-cdp-docker


## Credits

Heavily inspired by https://github.com/JakeWharton/docker-gphotos-sync.
