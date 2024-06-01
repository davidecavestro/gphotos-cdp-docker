# docker-gphotos-cdp

A container image based on [gphotos-cdp](https://github.com/perkeep/gphotos-cdp) and [chromedp/headless-shell](https://github.com/chromedp/docker-headless-shell) to download items from Google Photos with their original geo-location attributes, at original quality.


## Example usage

### Create a browser profile

Launch the browser with a profile from scratch into an empty folder and complete the authentication.
```bash
google-chrome \
  --user-data-dir=/path/to/gphotos/profile_family \
  --no-first-run  \
  --password-store=basic \
  --use-mock-keychain \
  https://photos.google.com/
```
Close the browser: the folder you chose is enough to open a headless browser and access your photos.


### Configure docker compose

Launch the container mounting the profile folder and the directory where
you want to download your stuff

```compose.yml
---
version: "3"

services:
  gphoto:
    image: davidecavestro/gphotos-cdp:dev-main
#    command: -start https://photos.google.com/photo/abcd1234...
    working_dir: /download
    volumes:
    - /etc/localtime:/etc/localtime
    - /path/to/gphotos/profile_family:/tmp/gphotos-cdp
    - /Volume1/Photos/data_gphotos:/dest
    environment:
    - DEST_DIR=/dest
    restart: no

```


## Schedule from your host crontab

Configure it so that running `crontab -l` reveals:
```bash
0 20 * * * docker compose --project-name gphotos_family -f /path/to/gphotos/compose.yml up -d
```

## Credits

Heavily inspired by https://github.com/JakeWharton/docker-gphotos-sync.