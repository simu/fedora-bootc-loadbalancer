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
  tcpdump \
  yq

# TEMP: install selinux helpers
# TODO(sg): decide if we keep these?
dnf5 install -y --setopt=install_weak_deps=0 \
  audit \
  policycoreutils-python-utils \
  setroubleshoot-server

curl -Lo /tmp/floaty.rpm https://github.com/vshn/floaty/releases/download/v1.4.0/floaty_linux_amd64.rpm
dnf5 install -y /tmp/floaty.rpm
dnf5 clean all

## install bootc-loadbalancer-controller-manager TODO(sg): do this right!
cp /ctx/bootc-loadbalancer-controller-manager /usr/bin/bootc-loadbalancer-controller-manager
cp /ctx/bootc-loadbalancer-controller-manager.service /usr/lib/systemd/system/bootc-loadbalancer-controller-manager.service
mkdir -p /etc/bootc-loadbalancer-controller-manager

rm -rf /run/cloud-init
rm -rf /run/dnf
rm -rf /var/lib/dnf
rm -rf /var/lib/net-snmp

# rename default user in cloud-init config
yq -i '.system_info.default_user.name="core" | .system_info.default_user.gecos="CoreOS default admin user" | .network.config="disabled"' \
  /etc/cloud/cloud.cfg

cat >/usr/lib/tmpfiles.d/lb.conf << EOF
d /var/lib/cloud
d /var/lib/haproxy
d /var/lib/keepalived
d /var/lib/prometheus
EOF

## Enable systemd services

systemctl enable \
  bootc-loadbalancer-controller-manager \
  conntrackd \
  firewalld \
  haproxy \
  keepalived \
  prometheus-node-exporter

cat >/usr/lib/systemd/system-preset/00-load-balancer-services.preset <<EOF
enable bootc-loadbalancer-controller-manager
enable conntrackd
enable firewalld
enable haproxy
enable keepalived
enable prometheus-node-exporter
EOF

## Configure SELinux HAProxy ports
semanage port -a -t http_port_t -p tcp 1936   # Ingress backend healthcheck port
semanage port -a -t http_port_t -p tcp 6443   # OpenShift API
semanage port -a -t http_port_t -p tcp 8888   # HAProxy stats
semanage port -a -t http_port_t -p tcp 22623  # Ignition

## Setup custom SELinux policies
for policy in keepalived-floaty floaty; do
  checkmodule -M -m -o "/tmp/${policy}.mod" "/ctx/${policy}.te"
  semodule_package -o "/tmp/${policy}.pp" -m "/tmp/${policy}.mod"
  semodule -i "/tmp/${policy}.pp"
done

## Setup default configs

cp /ctx/floaty-global.wrapper /usr/sbin/floaty-global.wrapper.sh
cp /ctx/haproxy.cfg /etc/haproxy/haproxy.cfg
cp /ctx/keepalived.conf /etc/keepalived/keepalived.conf
mkdir -p /etc/keepalived/conf.d
# TODO: probably remove this, since we most likely can't generate a working generic config
cp /ctx/conntrackd.conf /etc/conntrackd/conntrackd.conf
cp /ctx/sysctl-10-loadbalancer-gateway.conf /usr/lib/sysctl.d/10-loadbalancer-gateway.conf

# TODO: remove? or actually restorecon?
restorecon -n -v
