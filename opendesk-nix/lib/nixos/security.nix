# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

#"""
# NixOS Security Library for openDesk Containers
# Implements security hardening for all container types
# OpenSpec: FR-IMAGE-001, FR-IMAGE-002, FR-IMAGE-003, FR-SEC-001
#"""

{ pkgs, lib, ... }:

let
  # Capability definitions for container security
  capabilities = rec {
    # Network capabilities
    net_bind_service = true;
    net_raw = false;
    
    # File system capabilities
    chown = false;
    setgid = true;
    setuid = true;
    sys_chroot = true;
    
    # Process capabilities
    kill = true;
    sys_nice = false;
    
    # Security capabilities
    ipc_lock = false;
    sys_admin = false;
    sys_module = false;
    sys_boot = false;
    sys_rawio = false;
    
    # Default capabilities for different service types
    default = {
      net_bind_service = true;
      setgid = true;
      setuid = true;
      sys_chroot = true;
      kill = true;
    };
    
    database = default // {
      chown = true;
    };
    
    web = {
      net_bind_service = true;
      setgid = false;
      setuid = false;
    };
    
    cache = default;
    
    minimal = {
      net_bind_service = true;
    };
  };

  # Seccomp profiles
  seccompProfiles = rec {
    default = pkgs.writeText "seccomp-default.json" ''
      {
        "defaultAction": "SCMP_ACT_ERRNO",
        "syscalls": [
          {
            "names": ["accept", "access", "arch_prctl", "bind", "brk", "chmod", 
                     "chown", "clock_gettime", "clone", "close", "connect", 
                     "dup", "dup2", "epoll_create", "epoll_create1", "epoll_ctl",
                     "execve", "exit", "exit_group", "faccessat", "fchmod", 
                     "fchmodat", "fchown", "fchownat", "fcntl", "fstat", 
                     "fstatfs", "futex", "getdents", "getdents64", "geteuid", 
                     "getgid", "getpid", "getppid", "getrandom", "getrlimit",
                     "getuid", "ioctl", "listen", "lseek", "madvise", "mmap",
                     "mprotect", "munmap", "nanosleep", "open", "openat", "pause",
                     "poll", "prlimit64", "pread64", "pwrite64", "read", "readlink",
                     "rt_sigaction", "rt_sigprocmask", "rt_sigreturn", "sched_yield",
                     "select", "sendto", "set_robust_list", "set_tid_address",
                     "setsockopt", "shutdown", "sigaltstack", "socket", "splice",
                     "stat", "statfs", "sysinfo", "tgkill", "time", "timerfd_create",
                     "timerfd_settime", "unlink", "wait4", "write"],
            "action": "SCMP_ACT_ALLOW"
          }
        ]
      }
    '';
    
    strict = pkgs.writeText "seccomp-strict.json" ''
      {
        "defaultAction": "SCMP_ACT_ERRNO",
        "syscalls": [
          {
            "names": ["accept", "access", "brk", "chmod", "close", "connect", 
                     "dup", "dup2", "epoll_create", "epoll_ctl", "epoll_wait",
                     "execve", "exit", "exit_group", "faccessat", "fcntl", 
                     "fstat", "futex", "getdents", "getpid", "getppid", 
                     "getrandom", "ioctl", "listen", "lseek", "madvise",
                     "mmap", "mprotect", "munmap", "nanosleep", "open", 
                     "openat", "pause", "poll", "prlimit64", "pread64",
                     "pwrite64", "read", "rt_sigaction", "rt_sigprocmask", 
                     "rt_sigreturn", "sched_yield", "select", "sendto",
                     "set_robust_list", "set_tid_address", "setsockopt",
                     "socket", "stat", "sysinfo", "tgkill", "time", "wait4",
                     "write"],
            "action": "SCMP_ACT_ALLOW"
          }
        ]
      }
    '';
    
    database = seccompProfiles.strict;
    web = seccompProfiles.default;
  };

  # Security profiles for different container types
  securityProfiles = rec {
    default = {
      capabilities = capabilities.default;
      readOnlyRootFilesystem = false;
      noNewPrivileges = true;
      seccomp = seccompProfiles.default;
      tmpfs = [ "/tmp" ];
      
      # Process limits
      limits = {
        nofile = {
          soft = 65535;
          hard = 65535;
        };
        nproc = {
          soft = 4096;
          hard = 8192;
        };
        memlock = {
          soft = -1;
          hard = -1;
        };
      };
      
      # Kernel parameters
      sysctl = {
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
      };
    };
    
    database = securityProfiles.default // {
      capabilities = capabilities.database;
      readOnlyRootFilesystem = false;  # Databases need to write data
      seccomp = seccompProfiles.database;
      tmpfs = [ "/tmp" "/var/run/mysqld" ];
      
      # Database-specific limits
      limits = securityProfiles.default.limits // {
        nofile = {
          soft = 100000;
          hard = 100000;
        };
      };
    };
    
    web = securityProfiles.default // {
      capabilities = capabilities.web;
      readOnlyRootFilesystem = true;  # Web apps should be read-only
      seccomp = seccompProfiles.web;
      tmpfs = [ "/tmp" "/var/lib/nginx/tmp" ];
    };
    
    cache = securityProfiles.default // {
      capabilities = capabilities.cache;
      readOnlyRootFilesystem = false;
      seccomp = seccompProfiles.strict;
      tmpfs = [ "/tmp" ];
    };
    
    minimal = securityProfiles.default // {
      capabilities = capabilities.minimal;
      readOnlyRootFilesystem = true;
      seccomp = seccompProfiles.strict;
      tmpfs = [ "/tmp" ];
    };
  };

  # Function to apply security profile to a configuration
  applySecurityProfile = profile: config: 
  let
    secProfile = builtins.getAttr profile securityProfiles;
  in
  config // rec {
    # Apply capabilities
    security.containerFeatures = secProfile.capabilities;
    
    # Apply read-only filesystem
    boot.kernelPackages = if secProfile.readOnlyRootFilesystem then 
      pkgs.linuxPackages_hardened else pkgs.linuxPackages;
    
    # Apply seccomp
    security.seccomp = secProfile.seccomp;
    
    # Apply tmpfs
    fileSystems = (config.fileSystems or {}) // 
      builtins.listToAttrs (map (path: {
        name = path;
        value = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "size=100M" "mode=1777" ];
        };
      }) secProfile.tmpfs);
    
    # Apply limits
    security.limits = secProfile.limits;
    
    # Apply sysctl
    boot.kernel.sysctl = secProfile.sysctl;
    
    # Disable dangerous services
    services.openssh.enable = false;
    services.openssh.passwordAuthentication = false;
    services.openssh.allowRootLogin = "no";
    security.polkit.enable = false;
    security.sudo.enable = false;
    
    # Security hardening for users
    users.users.root.password = "!";
    users.users.root.lockPasswd = true;
    
    # No new privileges
    security.noNewPrivileges = true;
  };

  # Standard security configuration for all containers
  standardSecurity = applySecurityProfile "default";

  # Database-specific security
  databaseSecurity = applySecurityProfile "database";
  
  # Web server security
  webSecurity = applySecurityProfile "web";
  
  # Cache server security
  cacheSecurity = applySecurityProfile "cache";

in rec {
  inherit capabilities seccompProfiles securityProfiles;
  inherit applySecurityProfile;
  inherit standardSecurity databaseSecurity webSecurity cacheSecurity;

  # Function to create a secure container configuration
  mkSecureContainer = {
    name,
    config,
    profile ? "default",
    ...
  }:
  applySecurityProfile profile config;

  # Function to add security to existing services
  withSecurity = { name, serviceConfig }: 
    serviceConfig // rec {
      imports = (serviceConfig.imports or [ ]) ++ [ ./security.nix ];
      services.${name}.openFirewall = false;
    };

  # Function to create a security-hardened user
  mkSecureUser = {
    name,
    uid ? 1000,
    gid ? 1000,
    home ? "/home/${name}",
    shell ? pkgs.bash,
    systemUser ? true,
    ...
  }:
  {
    users.users.${name} = {
      isSystemUser = systemUser;
      uid = uid;
      gid = gid;
      group = name;
      home = home;
      shell = shell;
      description = "${name} service user";
      passwords = [ "!" ];  # Disable password login
      lockPasswd = true;
      openssh.authorizedKeys.keys = [ ];  # No SSH keys by default
    };
    
    users.groups.${name} = {
      gid = gid;
    };
  };

  # Function to create secure directories
  mkSecureDirs = {
    paths ? [ ],
    owner ? "nobody",
    group ? "nogroup",
    mode ? "750",
    ...
  }:
  lib.mkAfter (builtins.concatMap (path: ''
    mkdir -p ${path}
    chown -R ${owner}:${group} ${path}
    chmod -R ${mode} ${path}
  '') paths);
}
