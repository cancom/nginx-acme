#!/usr/bin/env bash
# vim: set ft=sh :
# shellcheck disable=SC1117,SC2181

display_help()
{
  echo "Usage: $0 [OPTION] yoursubdomain.com" >&2
  echo
  echo "Options:"
  echo "   -c, --create               Obtain a LE certificate and create Virtual Host"
  echo "   -d, --delete               Delete existing Virtual Host and LE certificate"
  echo "   -t, --test                 Obtain a test (staging) LE certificate"
  echo "   --find-my-ip               Find your public IP that you can use for DNS entry"
  echo
  exit 1
}

say ()
{
echo "$@" | sed \
  -e "s/\(\(@\(red\|green\|yellow\|blue\|magenta\|cyan\|white\|reset\|b\|u\)\)\+\)[[]\{2\}\(.*\)[]]\{2\}/\1\4@reset/g" \
  -e "s/@red/$(tput setaf 1)/g" \
  -e "s/@green/$(tput setaf 2)/g" \
  -e "s/@yellow/$(tput setaf 3)/g" \
  -e "s/@blue/$(tput setaf 4)/g" \
  -e "s/@magenta/$(tput setaf 5)/g" \
  -e "s/@cyan/$(tput setaf 6)/g" \
  -e "s/@white/$(tput setaf 7)/g" \
  -e "s/@reset/$(tput sgr0)/g" \
  -e "s/@b/$(tput bold)/g" \
  -e "s/@u/$(tput sgr 0 1)/g"
}

if [[ $# -lt 2 ]] && [ "$1" != "--find-my-ip" ]; then
  display_help
fi

if [ "$1" != "--find-my-ip" ]; then
  DOMAIN=$2
  VALIDATE_HOSTNAME=$( echo "${DOMAIN}" | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)' )
  if [[ -z $VALIDATE_HOSTNAME ]]; then
    say @b@red[["Invalid hostname: ${DOMAIN}"]]
    say @b@red[["Exiting.."]]
    exit 1
  fi
fi

create_vhost ()
{
  if [ -f "/etc/nginx/sites-available/${DOMAIN}.conf" ]; then
    say @b@red[["vHost for ${DOMAIN} already exists."]]
    say @b@red[["You may remove it using manage-vhosts --delete ${DOMAIN} before trying again."]]
    say @b@red[["Exiting.."]]
    exit 1
  fi

  if [ -d "/acmecerts/${DOMAIN}" ]; then
    if openssl x509 -noout -issuer -in "/acmecerts/${DOMAIN}/ca.cer" | grep -ci staging; then

      say @b@red[["vHost for ${DOMAIN} already exists with staging issuer."]]
      say @b@red[["Do you want to remove it?"]]

      read -p "Are you REALLY REALLY sure? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "/acmecerts/${DOMAIN}"
      fi
    fi
  fi

  acme.sh --issue --domain "${DOMAIN}" --webroot /var/www/_letsencrypt --keylength 4096
  if [ $? -ne 0 ]; then
    echo
    say @b@red[["Unable to obtain certificate for ${DOMAIN}!"]]
    say @b@red[["Exiting.."]]
    exit 1
  fi
  echo
  say @b@green[["Successfully obtain certificate for ${DOMAIN}."]]
  mkdir -p /var/www/"${DOMAIN}"/{logs,html}
  echo "Creating vHost"
  sed "s|subdomain.example.com|${DOMAIN}|g" /etc/nginx/vhost.template > /etc/nginx/sites-available/"${DOMAIN}".conf
  ln -s /etc/nginx/sites-available/"${DOMAIN}".conf /etc/nginx/sites-enabled/"${DOMAIN}".conf
  echo "Checking if config is OK and reloading NGINX"
  nginx -t && /etc/init.d/nginx reload
  if [ $? -ne 0 ]; then
    say @b@red[["There seem to be an issue with NGINX configs--see above."]]
    say @b@red[["Please try to fix it and reload nginx again"]]
    exit 1
  else
    say @b@green[["NGINX config looks OK. Well done!"]]
    say @b@green[["You may now visit your website using: https://${DOMAIN}"]]
  fi
}

delete_vhost ()
{
  say @b@red[["This will remove vHost configuration and certificates for ${DOMAIN}."]]
  say @b@red[["This is irreversible!"]]
  read -p "Are you REALLY REALLY sure? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [ -f "rm /etc/nginx/sites-enabled/"${DOMAIN}".conf" ]; then 
        rm /etc/nginx/sites-available/"${DOMAIN}".conf /etc/nginx/sites-enabled/"${DOMAIN}".conf
	  else
	    say @b@yellow[["Site was already deactivated. Skipping."]]
	  fi

      if [ -d "/acmecerts/${DOMAIN}" ]; then
        acme.sh --revoke -d "${DOMAIN}"
        acme.sh --remove -d "${DOMAIN}"
    	rm -rf /acmecerts/"${DOMAIN}"
      else
	    say @b@yellow[["Certificate was already revoked. Skipping."]]
	  fi
  fi

  nginx -t && /etc/init.d/nginx reload
}

test_certificate_staging ()
{
  acme.sh --issue --domain "${DOMAIN}" --webroot /var/www/_letsencrypt --keylength 4096 --test
  if [ $? -ne 0 ]; then
    echo
    say @b@red[["Unable to obtain certificate for ${DOMAIN}!"]]
    say @b@red[["Exiting.."]]
    exit 1
  fi
  echo
  say @green[["Successfully obtained a test (Let's Encrypt Staging) certificate for ${DOMAIN}!"]]
  say @b@green[["You may now go ahead and use: manage-vhosts --create ${DOMAIN}!"]]
}

find_public_ip ()
{
  say @b@yellow[["Your public IP seems to be: $(curl -s https://ip.cancom.io)"]]
  say @yellow[["You may point your (sub)domain to this IP."]]
  say @yellow[["Your IP might be different in case you are using NAT or different internet gateway!"]]
  say @yellow[["It's just a best effort guess!"]]
}

case "$1" in
  -c|--create) create_vhost ;;
  -d|--delete) delete_vhost ;;
  -t|--test) test_certificate_staging ;;
  --find-my-ip) find_public_ip ;;
  *) display_help ;;
esac