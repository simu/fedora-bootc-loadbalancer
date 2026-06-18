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

The bootable container build process compiles the Kubernetes controller
implemented by [simu/bootc-load-balancer-controller] and copies the resulting
binary to `/usr/bin/bootc-loadbalancer-controller-manager` in the bootable
container.

You can also check out the the [VSHN blog post] for more details on
this project.

[Universal Blue image-template repo]: https://github.com/ublue-os/image-template
[simu/bootc-load-balancer-controller]: https://github.com/simu/bootc-load-balancer-controller
[VSHN blog post]: https://www.vshn.ch/en/blog/building-a-modern-load-balancer-and-nat-gateway-with-fedora-bootable-containers/
