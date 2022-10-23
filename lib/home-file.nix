# lib/home-file.nix
files:
let
  link = origin: target: "L+ ${target} - - - - ${origin}";
  #home = "/home/jsh/";
in {
  systemd.tmpfiles.rules = map ({origin,target}: link origin "${target}") files;
}
