{ pkgs, ... }:

# This PoC was written by Álvaro Castillo 
#
# Tested on nixOS 25.05 stable.
#

{

  packages = [ 
        pkgs.selinux-python
        pkgs.selinux-sandbox
        pkgs.selinux-refpolicy
        pkgs.libselinux
        pkgs.checkpolicy
        pkgs.setools
        pkgs.policycoreutils
        pkgs.libsemanage
        pkgs.libsepol
        pkgs.semodule-utils
        pkgs.m4
        pkgs.libxml2
        pkgs.zlib
    ];

  languages = {
    python = {
      enable = true;
      venv.enable = true;
    };
  };
    env = {
        
    };
    scripts = {
        git_submodules_setup = {
            exec = ''
                git submodule update --init --recursive
                git checkout RELEASE_2_20250213
                git pull origin RELEASE_2_20250213
                '';
        };

        patch_makefile = {
            exec = ''
                get_nix_store_path=$(dirname $(whereis semodule |awk '{print $3}'))
                sed -ie "s|REPLACE_WITH_NIX_STORE_CUSTOM_PATH|$get_nix_store_path|g" devenv/files/Makefile
                diff -u selinux/refpolicy/Makefile devenv/files/Makefile > devenv/patches/Makefile.patch
                patch selinux/refpolicy/Makefile < devenv/patches/Makefile.patch
            '';
        };

        patch_build_conf = {
          exec = ''
                diff -u selinux/refpolicy/build.conf devenv/files/build.conf > devenv/patches/build.conf.patch
                patch selinux/refpolicy/build.conf < devenv/patches/build.conf.patch
            '';

        };

        clean_compile = {
          exec = ''
            make bare
            rm -rf tmp/ policy.conf policy.32 policy.34
            rm -f *.mod *.mod.fc *.mod.if *.pp
            rm -rf config.tmp/ build/ out/ tags
          '';
        };

        setup_config = {
          exec = ''
            run0 cp files/config /etc/selinux/
            run0 mount -t selinuxfs selinuxfs /sys/fs/selinux
          '';
        };

        compiling_policies = {
          exec = ''
            make conf
            make
          '';
        };

        installing_policies = {
          exec = ''
            make DESTDIR=$PWD/install-root INSTALL_POLICY=$PWD/install-root/etc/selinux/targeted install
            run0 mkdir -p /etc/selinux/targeted
            run0 cp -r $PWD/install-root/etc/selinux/targeted/* /etc/selinux/targeted
            run0 setfiles -F -v /etc/selinux/targeted/contexts/files/file_contexts /
          '';
        };

        
    };

  enterShell = ''
    # Update the source code
    cd ../selinux/refpolicy
    git_submodules_setup
    
    # Generate and apply patches
    cd ../../
    patch_makefile
    patch_build_conf

    # Compiling the policies
    cd selinux/refpolicy
    compiling_policies

    # Setup SELinux config
    setup_config

    # Installing policies
    installing_policies
    
  '';

}
