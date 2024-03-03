{
  system = "x86_64-linux";
  modules = [({pkgs, ...}: {
    copper.features = [
      "cli"
      "fish"
      "neovim"
      "git"
      "link-config"
      "lunarvim"
      "chroma"
      "nixos/hyprland"
      "nixos/waybar-hyprdots"
      "nixos/dunst"
      "nixos/rofi"
      "nixos/swaylock"
      "nixos/wlogout"
      "nixos/swim"
      "nixos/_1password"
    ];

    copper.feature.nixos._1password.gitSigning.enable = true;

    home.packages = with pkgs; [
      gnome.nautilus
      vscode
      firefox
    ];

    copper.chroma = {
      fish.enable = false;
      starship.enable = false;
      bat.enable = false;

      desktop.enable = true;
      gtk.enable = true;
      gtk.gtk4.libadwaitaSupport = "patch-binary";
      qt.enable = true;
    };
  })];
}
