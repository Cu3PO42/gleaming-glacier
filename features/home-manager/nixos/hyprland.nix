{
  lib,
  config,
  pkgs,
  options,
  copper,
  ...
} @ opts: {
  copper.file.config = lib.genAttrs ["hypr/animations.conf" "hypr/entry.conf" "hypr/keybindings.conf" "hypr/nvidia.conf" "hypr/windowrules.conf"] (n: "config/${n}");
  wayland.windowManager.hyprland = {
    enable = true;
    # TODO: this also installs a hyprland package, how does this conflict with the global install
    package = copper.inputs.hyprland;
    systemd.enable = true;
    # Needed so that waybar, etc. have a complete environment
    systemd.variables =
      options.wayland.windowManager.hyprland.systemd.variables.default
      ++ [
        "XDG_DATA_DIRS"
        "XDG_CONFIG_DIRS"
        "PATH"
      ];
    # TODO: nvidia patches are no longer needed, but does that extend to the nvidia conf file?
    settings.source = lib.mkMerge [(lib.mkIf false ["${config.xdg.configHome}/hypr/nvidia.conf"]) ["${config.xdg.configHome}/hypr/entry.conf"]];
  };

  home.packages = [copper.packages.systemctl-toggle pkgs.procps];

  systemd.user.services.polkit-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.polkit_gnome.out}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "always";
      # TODO: dbus activation isn't working for the Gnome Agent for some reason
      #BusName = "org.freedesktop.PolicyKit1.AuthenticationAgent";
    };

    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.hyprdots-batterynotify = {
    Unit = {
      Description = "Battery notification from hyprdots";
      Documentation = "https://github.com/prasanthrangan/hyprdots";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${copper.packages.misc-scripts-hyprdots}/bin/batterynotify.sh";
      Restart = "always";
    };

    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.chroma-launch = {
    Unit = {
      Description = "Set up theming scripts";
      After = ["graphical-session-pre.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${config.copper.chroma.themeDirectory}/active/activate";
      Restart = "always";
    };

    Install.WantedBy = ["hyprland-session.target"];
  };

  services.network-manager-applet.enable = true;
  services.blueman-applet.enable = true;

  programs.kitty.enable = true;
  programs.kitty.font.name = "CaskaydiaCove Nerd Font Mono";
  programs.kitty.extraConfig = ''
    window_padding_width 5
  '';
}
