#! /bin/bash

if [ -d "/.jsh-nix" ]; then
  exit 0
else
  git clone git@github.com:jshcmpbll/jsh-nix.git /.jsh-nix
  cat configuration.nix > /etc/nixos/configuration.nix
  exit 0
fi
