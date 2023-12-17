{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    # lock & turn off monitor after 20 mins, suspend after 30 mins // install swayidle
    exec-once = ["swayidle -w timeout 1200 'swaylock; hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' timeout 1800 'systemctl suspend'"];
  };

  home.packages = with pkgs; [
    swaylock-effects
    swayidle
  ];
}
