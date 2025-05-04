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

### Schedule with ofelia and expose a browser for relogins

I currently prefer scheduling from [ofelia job schedule](https://github.com/mcuadros/ofelia) container.
I've also added a containerized browser, configured to share the profile, that can be used to
renew the session when tokens expire. The _containerized browser_ is reachable at the specified
port from the _host browser_, i.e. at http://localhost:3000.

```compose.yml
---
version: "3"

services:
  chadburn:
    image: mcuadros/ofelia:latest
    depends_on:
    - gphoto
    command: daemon
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  gphoto:
    image: davidecavestro/gphotos-cdp:latest
#    command: -start https://photos.google.com/photo/abcd1234...
    working_dir: /download
    user: ${UID}:${GID}
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
      ofelia.enabled: "true"
      ofelia.job-exec.synccron.schedule: "@hourly"
      ofelia.job-exec.synccron.command: "date && /usr/local/bin/gphotos-cdp -v -dev -headless -dldir /download -run /usr/local/bin/save.sh"
      ofelia.job-exec.synccron.no-overlap: "true"
  chrome:
    image: kasmweb/chrome:1.15.0-rolling
    user: ${UID}:${GID}
    environment:
      - VNC_PW=${VNC_PW}
      - TZ=Europe/Rome
      - LAUNCH_URL=https://photos.google.com/
    volumes:
      - /path/to/gphotos/profile_family:/home/kasm-user/.config/google-chrome/
    ports:
      - 6901:6901
    shm_size: 512mb
    restart: unless-stopped
    profiles:
      - relogin
```

Please note in the above example the browser is not started automatically, unless
the _relogin_ profile is activated.

## How to build locally

The Dockerfile currently builds gphotos-cdp from a locally cloned repo
([a fork](https://github.com/davidecavestro/gphotos-cdp) with some customizations) but avoids cloning it directly;
instead the automated build on GH has a dedicated clone step.

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

## FAQs

<dl>
  <dt>
    The container exits complaining <tt>Authentication not possible in -headless mode</tt>
  </dt>
  <dd>
    This usually means that the session has been invalidated, so you have to relogin using a browser.
    You can use any browser to relogin: the key point is using the same profile shared with the container.
    For an example of containerized browser check https://github.com/davidecavestro/gphotos-cdp-docker/issues/1#issuecomment-2823168106.
  </dd>
</dl>


## Image project home

https://github.com/davidecavestro/gphotos-cdp-docker


## Credits

Heavily inspired by https://github.com/JakeWharton/docker-gphotos-sync.
