# docker-gphotos-cdp

A container image based on [gphotos-cdp](https://github.com/perkeep/gphotos-cdp) and [chromedp/headless-shell](https://github.com/chromedp/docker-headless-shell) to download photos and videos from your account without loosing geo-location attributes.

By default each downloaded file is passed to _[save.sh](save.sh)_ which detects its type, extracts the _creation date/time_ and moves it to a `year/ywar-month` subfolder within a _target_ directory.
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


## Schedule from your host crontab

Optionally configure cron, i.e. for me running `crontab -l` reveals:
```bash
0 20 * * * docker compose --project-name gphotos_family -f /path/to/gphotos/compose.yml up -d
```

## Image project home

https://github.com/davidecavestro/gphotos-cdp-docker


## Credits

Heavily inspired by https://github.com/JakeWharton/docker-gphotos-sync.
