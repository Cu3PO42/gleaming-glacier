{config, lib, origin, pkgs, copper, ...}: with lib; let
  cfg = config.copper.feature.nixos.hyprlock;
in {
  featureOptions = {
    suspend.enable = mkEnableOption "Automatic sleep via Hypridle";
  };

  config = {
    assertions = [
      {
        assertion = config.copper.feature.nailgun.enable;
        message = "Nailgun is required to ensure Hyprlock gets only PNG backgrounds";
      }
    ];

    programs.hyprlock = {
      enable = true;
      package = copper.inputs.hyprlock;

      # This configuration is derived from the config at
      # https://github.com/TheRiceCold/dots/blob/main/home/wolly/kaizen/desktop/wayland/hyprland/ecosystem/hyprlock/default.nix
      # It is shared originally under the terms of the MIT license.
      settings = {
        general = { 
          grace = 5;
          hide_cursor = true;
        };
  
        background = {
          monitor = "";
          blur_size = 4;
          blur_passes = 3;
          noise = 0.0117;
          contrast = 1.3000;
          brightness = 0.8000;
          vibrancy = 0.2100;
          vibrancy_darkness = 0.0;
          path = "${config.copper.feature.nailgun.activeWallpaperDir}/png";
        };
  
        image = [
          {
            size = 300;
            rounding = -1;
            halign = "center";
            valign = "center";
            position = "0, -4";
            path = "${../../../assets/Cu3PO42.png}";
          }
        ];
  
        # TODO: integrate colors with Chroma
        input-field = [
          { # Password
            monitor = "";
            halign = "center";
            valign = "bottom";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.5; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            fade_on_empty = true;
            position = "0, 225";
            font_color = "rgb(142, 149, 177)";
            inner_color = "rgba(0, 0, 0, 0)";
            outer_color = "rgba(0, 0, 0, 0)";
            fail_color = "rgb(183, 105, 150)";
            size = "200, 40";
            placeholder_text = ''<i>Password</i>'';
          }
        ];
        label = let
          monitor =  "";
          font_family = "Ubuntu Nerd Font";
          color = "rgba(211, 228, 228, 0.75)";
          date = int: format: ''cmd[update:${int}] echo "$(date +"${format}")"'';
        in [
          { # Date
            font_size = 16;
            valign = "top";
            halign = "center";
            text = date "5000" "%A, %d %B";
            position = "0, -115";
            inherit monitor font_family color;
          }
          { # Time
            font_size = 72;
            valign = "top";
            halign = "center";
            text = date "1000" "%I:%M";
            position = "0, -140";
            inherit monitor font_family color;
          }
  
          { # User
            font_size = 20;
            halign = "center";
            valign = "center";
            position = "0, -200";
            text = ''Hi there, $USER'';
            inherit monitor font_family color;
          }
        ];
      };
    };

    services.hypridle = {
      enable = true;
      package = copper.inputs.hypridle;
      settings = {
        general = {
          # From Hyprland Wiki: to avoid having to press two keys to turn the display on.
          after_sleep_cmd = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dmps on";

          before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
          lock_cmd = lib.getExe config.programs.hyprlock.package;
        };
  
        listener = [
          {
            timeout = 300;
            on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
          }
        ] ++ (optional cfg.suspend.enable {
          timeout = 600;
          on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
        });
      };
    };

    copper.feature.nailgun.enable = true;
  };
}
