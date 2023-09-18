{pkgs, ...}: {
  # Load the driver immediately at boot.
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [ "amdgpu.freesync_video=1" ];

  # Enable 3D acceleration
  hardware.opengl = {
    # Acceleration via Mesa
    enable = true;
    # Direct Redering Interface, enables Vulkan in particular
    driSupport = true;
  };
}