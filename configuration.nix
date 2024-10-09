# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
# test
{ config, pkgs, ... }:

let
  # Import the custom Blackmagic Desktop Video package
  blackmagicDesktopVideo = import /etc/nixos/blackmagic/desktop-video.nix {
    inherit (pkgs) stdenv cacert curl runCommandLocal lib autoPatchelfHook libcxx libGL gcc7;
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./blackmagic/ffmpeg-decklink.nix
#      ./blackmagic/local-desktopvideo.nix #requires 2 desktop video .deb files in /homes/hitech/Blackmagic #TODO: Get this more magically
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "encoder"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Graphics Card
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hitech = {
    isNormalUser = true;
    description = "Hitech";
    extraGroups = [ "networkmanager" "wheel" "docker" "www-data" ];
    packages = with pkgs; [
      firefox
    #  kate
    #  thunderbird
    ];
  };

  users.users.tristonyoder = {
    isNormalUser = true;
    description = "tristonyoder";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      gh
    #  kate
    #  thunderbird
    ];
  };

  # Allow Passwordless sudo #TODO: Not this!!!!!
  security.sudo.wheelNeedsPassword = false;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "hitech";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    blackmagic-desktop-video-full = pkgs.callPackage ./blackmagic/desktop-video.nix {};
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    powerline-fonts
    ffmpeg_7-full
    blackmagic-desktop-video
    pkgs.linuxKernel.packages.linux_xanmod_stable.decklink
    nginx
    vsftpd
    git
    vlc
    gcc
    mysql
    obs-studio
    tree
  ];

  hardware.decklink.enable = true;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedTlsSettings = true;

    user = "nginx";
    group = "www-data";

    virtualHosts."10.10.254.148" = {
      locations = {
        "/" = {
          root = "/var/www/encoder";
          index = "index.html";
        };
        "/hls/" = {
          alias = "/var/www/encoder/playlisttest/";
          extraConfig = ''
            types {
              application/vnd.apple.mpegurl m3u8;
            }
          '';
        };
        "/ts/" = {
          alias = "/var/www/encoder/tstest/";
          extraConfig = ''
            types {
              video/mp2t ts;
            }
          '';
        };
      };
      extraConfig = ''
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
      '';
    };
  };

  # ... rest of your configuration ...
  systemd.tmpfiles.rules = [
    "d /var/www/encoder 0775 hitech www-data -"
  ];

  users.groups.www-data = {};

  # Add hitech and nginx users to www-data group
  users.users.nginx.extraGroups = [ "www-data" ];

  # Enable zsh
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  # Enable Oh-my-zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" "docker" "kubectl" ];
  };

  # Enable FTP
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    extraConfig = ''
      pasv_min_port=50000
      pasv_max_port=50100
      allow_writeable_chroot=YES
      local_root=/
    '';
  };

  # Enable SSH
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true; #TODO: Not this
  # Open Ports
  networking.firewall.allowedTCPPorts = [ 22 80 443 21 50000 50100 ];
  networking.firewall.allowPing = true;
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
  
  # Backup config @ each rebuild
  system.copySystemConfiguration = true;
}
