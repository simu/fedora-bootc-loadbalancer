# fedora-bootc-loadbalancer

:warning: DISCLAIMER: This repo contains early PoC quality code. Run at your own risk!

Repo for building a custom bootc loadbalancer image.

The base image includes HAProxy, Keepalived, Floaty, conntrackd, and
cloud-init.

The build step also configures SELinux, adds base configurations for HAProxy
and Keepalived, a wrapper script for Floaty, and base firewall rules.

This repository is based on the [Universal Blue image-template repo] (see
commit history and [README.image-template.md](/README.image-template.md) for
details).

[Universal Blue image-template repo]: https://github.com/ublue-os/image-template
