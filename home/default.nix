{ config, neomat, emacsnat, pkgs, ... }:

 import ../global-config.nix;


  agda = pkgs.agda.withPackages (p: [ p.standard-library ]); 
  {
  imports = [
    ./modules/git.nix
    ./modules/dots.nix
    ./modules/fish.nix
    ./modules/starship.nix
    ./modules/alacritty.nix
    "${flake.inputs.neomat}/neomat.nix"
    "${flake.inputs.emacsmat}/emacsmat.nix"
  ];

  programs = {
    home-manager.enable = true;
    command-not-found.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
        enableFlakes = true;
      };
    };
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  home.packages = with pkgs; [
    # chat
    tdesktop
    discord
    slack-dark

    # dev
    agda

    # tools
    docker-compose
    insomnia
    qbittorrent
    gitAndTools.gh
    exodus
    earthly
    awscli2
    ngrok
    flyctl
    gcolor3
    t-rec
    heroku

    # audio
    spotify

    # text
    zotero
    texlive.combined.scheme-full

    # images
    peek
    flameshot
    imagemagick

    # others
    any-nix-shell
    bitwarden-cli
    zoom-us

    # DOOM Emacs dependencies
    binutils
    (ripgrep.override { withPCRE2 = true; })
    gnutls
    zstd
    editorconfig-core-c
    emacs-all-the-icons-fonts
  ];

  home.stateVersion = "21.03";
}