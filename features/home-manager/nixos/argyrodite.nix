{config, origin, pkgs, lib, ...}: with lib; let
  cfg = config.copper.feature.nixos.argyrodite;

  buildConfig = src: pkgs.stdenvNoCC.mkDerivation {
    name = "ags-config";
    inherit src;
    nativeBuildInputs = with pkgs; [esbuild fd];
    buildPhase = ''
      fd --glob '*.ts' | xargs esbuild --outdir=.
    '';
    installPhase = ''
      mkdir $out
      mv ./* $out/
    '';
  };
in {
  imports = [
    origin.inputs.ags.homeManagerModules.default
  ];

  featureOptions = {
    develop.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        If enabled, do not pre-compile the AGS configuration, but just link the
        config directory. This will require you to manually build the
        configuration, but makes faster iteration easy.
      '';
    };

    polkitAgent.enable = mkEnableOption "Enable our own Polkit Agent" // { default = true; };
  };

  config = mkMerge [
    {
      programs.ags = {
        enable = true;
      };

      systemd.user.services.argyrodite = {
        Unit = {
          Description = "Aylur's Gtk Shell - Copper's configuration";
          Documentation = "https://aylur.github.io/ags-docs/";
          After = ["graphical-session-pre.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          ExecStart = "${config.programs.ags.finalPackage}/bin/ags -b argyrodite -c '${config.xdg.configHome}/argyrodite/config.js'";
          Restart = "always";
          BusName = "com.github.Aylur.ags.argyrodite";
        };
      };

      xdg.configFile."argyrodite.json".text = builtins.toJSON { polkit = cfg.polkitAgent.enable; };
    }
    (mkIf cfg.develop.enable {
      copper.file.config."argyrodite" = "config/argyrodite";
    })
    (mkIf (!cfg.develop.enable) {
      xdg.configFile."argyrodite".source = buildConfig ../../../config/argyrodite;
    })
  ];
}