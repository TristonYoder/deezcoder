{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./local-desktopvideo.nix {}
