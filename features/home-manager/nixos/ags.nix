{config, origin, pkgs, lib, ...}: with lib; let
  cfg = config.copper.feature.nixos.ags;

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
  };

  config = mkMerge [
    {
      programs.ags = {
        enable = true;
      };

      systemd.user.services.ags = {
        Unit = {
          Description = "Aylur's Gtk Shell";
          Documentation = "https://aylur.github.io/ags-docs/";
          After = ["graphical-session-pre.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          ExecStart = "${config.programs.ags.finalPackage}/bin/ags";
          Restart = "always";
          BusName = "com.github.Aylur.ags.ags";
        };
      };
    }
    (mkIf cfg.develop.enable {
      copper.file.config."ags" = "config/ags";
    })
    (mkIf (!cfg.develop.enable) {
      xdg.configFile."ags".source = buildConfig ../../../config/ags;
    })
  ];
}