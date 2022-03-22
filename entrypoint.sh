#!/bin/bash -e

if [ ! -z ${EXTERNAL_IP+x} ];
then
  export EXTERNAL_IP=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

IFS=', ' read -ra array <<< "$ALLOWED_CLIENTS"
printf '%s\n' "${array[@]}" > /etc/dnsdist/allowedClients.acl


sed -i "s/DNSDIST_BIND_IP/$DNSDIST_BIND_IP/" /etc/dnsdist/dnsdist.conf && \
sed -i "s/EXTERNAL_IP/$EXTERNAL_IP/" /etc/dnsdist/dnsdist.conf && \
chown -R root:_dnsdist -R /etc/dnsdist

echo "Starting DNSDist..."
/usr/bin/dnsdist --supervised --disable-syslog --uid _dnsdist --gid _dnsdist &
echo "Starting sniproxy"
/usr/sbin/sniproxy -c /etc/sniproxy.conf -f &

echo "[INFO] Using $EXTERNAL_IP - Point your DNS settings to this address"

wait -n