# Support unlocking any LUKS devices using the TPM
#
# In order for this to make any sense, you must be using secure boot.
{...}: {
  # Unlocking drives is performed in the initrd. However, unlocking via TPM is
  # only supported by systemd, thus we must use the new systemd-based initrd
  boot.initrd.systemd.enable = true;

  # Enable support for TPM2
  security.tpm2.enable = true;
  # The TCTI is the "Transmission Interface" that is used to communicate with a
  # TPM. Set the necessar environment variabls so tools can use it.
  security.tpm2.tctiEnvironment.enable = true;

  # Note that if you want to use this module, you must make sure that the driver
  # for your TPM is loaded in your initrd.
}
