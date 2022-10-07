#!/bin/sh
# vim:sw=4:ts=4:et

set -e
service cron start
echo "$(shuf -i 0-60 -n1) $(shuf -i 0-23 -n1) * * * acme.sh --cron --renew-hook 'nginx -t && /etc/init.d/nginx reload' --log >/dev/null" | crontab -
