#!/bin/bash
# vim: et sw=2

set -ouex pipefail

dnf5 install -y --setopt=install_weak_deps=0 \
  cloud-init \
  cloud-utils-growpart \
  conntrack \
  firewalld \
  haproxy \
  keepalived \
  node-exporter \
  yq

curl -Lo /tmp/floaty.rpm https://github.com/vshn/floaty/releases/download/v1.4.0/floaty_linux_amd64.rpm
dnf5 install -y /tmp/floaty.rpm
dnf5 clean all

rm -rf /run/cloud-init
rm -rf /run/dnf
rm -rf /var/lib/dnf
rm -rf /var/lib/net-snmp

# rename default user in cloud-init config
yq -i '.system_info.default_user.name="core" | .system_info.default_user.gecos="CoreOS default admin user"' \
  /etc/cloud/cloud.cfg

cat >/usr/lib/tmpfiles.d/lb.conf << EOF
d /var/lib/cloud
d /var/lib/haproxy
d /var/lib/keepalived
d /var/lib/prometheus
EOF

systemctl enable \
  conntrackd \
  firewalld \
  haproxy \
  keepalived \
  prometheus-node-exporter

cat >/usr/lib/systemd/system-preset/00-load-balancer-services.preset <<EOF
enable conntrackd
enable firewalld
enable haproxy
enable keepalived
enable prometheus-node-exporter
EOF

cp /ctx/floaty-global.wrapper /usr/sbin/floaty-global.wrapper.sh
cp /ctx/haproxy.cfg /etc/haproxy/haproxy.cfg
cp /ctx/keepalived.conf /etc/keepalived/keepalived.conf
cp /ctx/conntrackd.conf /etc/conntrackd/conntrackd.conf

restorecon -n -v
