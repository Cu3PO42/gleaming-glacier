---
title: Common Issues
---

# Common Issues

This document is intended as a list of issues I have run into while developing and deploying my various configurations.

## NixOS

### The system does not boot.

When using ZFS, the folders listed in `boot.zfs.devNodes` are searched for devices that are necessary to mount your pools.
While the default value should work just fine on a bare metal machine, in some virtualisation environments, the default `/dev/disk/by-id` might not exist.
In this case, you should consider setting it to include `/dev/disk/by-partid`, for example.
The existing virtualisation features do this where appropriate.

### I cannot log in.

Did you remember to set an initial password?
If not and you haven't set one in another way, you may be unable to login.
In this case, you may try logging in via SSH if enabled or otherwise revert to an earlier generation from the boot loader.
