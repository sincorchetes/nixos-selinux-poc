# Enable SELinux in NixOS (PoC)
This repository documents a Proof of Concept (PoC) to enable SELinux on NixOS.

> Warning: This setup is for academic and research purposes only. SELinux cannot label files under /nix/store, which is the foundation of the NixOS filesystem. As a result, this PoC does not provide complete MAC (Mandatory Access Control) capabilities.

# Why this is not production-ready
The core idea of SELinux is labeling and enforcing rules based on file context types.
In NixOS, the `/nix/store` is immutable and read-only, and SELinux cannot write labels to it.
Most binaries and services are executed directly from `/nix/store`, meaning they run under generic SELinux types like `unconfined_t` or `initrc_t`.

Therefore, even though SELinux is "enabled", it cannot actually enforce meaningful policies on most system components.

# What this PoC demonstrates
Enabling SELinux support in the kernel and early userspace.
Building and installing a SELinux policy (Refpolicy or custom).
Verifying SELinux enforcement status.
Observing AVC denials via `dmesg` or `audit` logs.
Understanding the limitations of SELinux in a Nix-based environment.

# Alternatives for real hardening
If you're serious about hardening NixOS, consider instead:
* AppArmor: supported natively and works well in NixOS.
* Landlock LSM: restricts system calls based on process-defined rules.
* Sandboxing tools: like `bubblewrap`, `nsjail`, or `firejail`.

These tools do not require persistent filesystem labeling and fit better with NixOS’s declarative and immutable model.

# SELinux integration is not officially supported
NixOS does not provide native support for SELinux. You won’t find `security.selinux.enable` or related options in the standard NixOS modules. This project uses manual configuration and policy compilation to make SELinux "appear" to work.

# Requirements

## SELinux kernel support
Add this section in to your `/etc/nixos/configuration.nix`

### Boot kernel support
```
boot.kernelParams = [
    "selinux=1"
    "enforcing=0"
  ];
```

### Compile systemd to support SELinux
```
systemd.package = pkgs.systemd.override {
    withSelinux = true;
  };
```

### Set the main LSM module
```
security.lsm = [ "selinux" "apparmor" ];
```

### Please add the SELinux tools
```
environment.systemPackages = with pkgs; [
    selinux-python
    selinux-sandbox
    selinux-refpolicy
    libselinux
    checkpolicy
    setools
    policycoreutils
    libsemanage
    libsepol
    semodule-utils
  ];
```

