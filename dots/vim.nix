{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { }).customize {
      name = "vim";
      #vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
      #  start = [
      #    #vim-nix
      #    #vim-lastplace
      #    #vimtex
      #  ];
      #  opt = [];
      #};
      vimrcConfig.customRC = ''
        syntax on
        set autoindent
        set expandtab
        set number
        set shiftwidth=2
        set softtabstop=2
        set bs=indent,eol,start
        set so=999
        set clipboard=unnamedplus
        set paste
        filetype plugin indent on
        let g:terraform_fmt_on_save=1
        let g:terraform_align=1
        let g:netrw_dirhistmax = 0
        let g:vimtex_quickfix_mode=0
        set conceallevel=1
        let g:tex_flavor = 'latex'
        let g:vimtex_view_general_viewer = 'zathura'
      '';
    }
    )
  ];
}
