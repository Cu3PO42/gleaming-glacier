#!/usr/bin/env nu

# This is the script we assume to be running in the install ISO

const secrets_path = "/iso/plate/secrets.tar.age"
const key_path = "/iso/plate/age_key"
const flake_source = "/iso/plate/flake"
const config_path = "/iso/plate/config.json"

# Schema for config.json:
# - disko: { devices: string[], script: string, encryption: boolean, encryptionKeyPath: string | null } | null
# - system: string
# - secureBoot: { keyBundle: string } | null
# - boot: { initrd: { availableKernelModules: string[] , kernelModules: string[] }, kernelModules: string[], extraModulePackages: string[] }
# - outputName: string
# - homeManager: { profiles: {user: string, profile: string}[] }

let config = open $config_path
let system = $config | get system

# -----------------------------------------------------------------------------
# External command helpers

def run-external-success [command: string, ...args: string] {
    try {
        do -c {
            ^$command ...$args
            true
        }
    } catch {
        false
    }
}


# -----------------------------------------------------------------------------
# Helpers

def confirm [message: string] {
    run-external-success gum confirm $message
}

def input_confirm [item: string, items: string] {
    loop {
        try {
            let pw = gum input --password --placeholder $"Enter the new ($item)"
            let confirm = gum input --password --placeholder $"Confirm the new ($item)"
            if $pw != $confirm {
                gum log -sl warn $"($items) do not match. Please try again."
                continue
            }
            return $pw
        }
    }
}

def decrypt_key [key_path: string, password: string] {
    run-external-success ssh-keygen "-p" "-P" $password "-N" "" "-f" $key_path "-q"
}

def check_subset [subset: list, superset: list] {
    for module in $subset {
        if not ($superset | any {$in == $module}) {
            return false
        }
    }
    return true
}


# -----------------------------------------------------------------------------
# Steps

def handle_root [] {
    if (^id -u | into int) != 0 {
        gum log -sl error "This script must be run as root."
        exit 1
    }
}

def handle_workdir [] {
    let success = run-external-success mkdir "-p" /run/plate
    if not $success {
        gum log -sl error "Cannot create working directory."
        exit 1
    }
}

def handle_secrets [] {
    if not ($secrets_path | path exists) {
        gum log -sl info "No secrets found. Skipping secrets extraction."
        mkdir /run/plate/secrets
        return
    }
    if ("/run/plate/secrets" | path exists) {
        gum log -sl info "Secrets already extracted. Skipping secrets extraction."
        return
    }
    # Copy the key to a writeable location because we need to fix permissions.
    cp $key_path /run/plate/age_key
    chmod 600 /run/plate/age_key
    gum log -sl info "Secrets detected. Password is required for extraction:"
    loop {
        let password = gum input --password | complete
        if $password.exit_code != 0 {
            gum log -sl warn "A password is required."
            continue
        }
        if (decrypt_key /run/plate/age_key ($password.stdout | str trim)) {
            gum log -sl info "Secrets extracted successfully."
            break
        } else {
            gum log -sl error "Failed to extract secrets. Please try again."
        }
    }
    mkdir /run/plate/secrets
    age -d -i /run/plate/age_key $secrets_path | tar -x -C /run/plate/secrets
}

def handle_partitioning [] {
    if ($config | get disko) != null {
        gum log -sl info "Disko detected, your partitions can be created automatically."
        if not (confirm "Do you want to create partitions automatically?") {
            handle_manual_partitioning
            return
        }
        if not (confirm $"The following devices will be wiped. All data on it will be lost.\n\n(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT ...($config | get disko.devices))") {
            gum log -sl error "Cannot continue with automatic partitioning."
            gum log -sl info "You can perform manual partitioning and rerun the installer, declining automatic partitioning."
            exit 1
        }
        if ($config | get disko.encryption) {
            # TODO: the way this is read is probably still bad
            let key = if (($config | get disko.encryptionKeyPath) != null) and ($config | get disko.encryptionKeyPath | path exists) {
                open ($config | get disko.encryptionKeyPath)
            } else {
                gum log -sl info "Disk encryption is enabled, but no pre-set key was provided."
                input_confirm "disk encryption key" "Keys"
            }
            # Change this once it is more flexible in ZFS/Disko feature module
            $key | save -f /tmp/dek.key
        }
        gum log -sl info "Automatically partitioning the devices. This may take a while."
        let success = run-external-success ($config | get disko.script)
        if $success {
            gum log -sl info "Automatic partitioning succeeded."
        } else {
            gum log -sl error "Automatic partitioning failed. Please see the output above to diagnose the issue, then rerun the installer."
            exit 1
        }
    } else {
        handle_manual_partitioning
    }
}

def handle_manual_partitioning [] {
    gum log -sl info "Manual partitioning is required. Please partition your devices and mount them to /mnt."
    if not (confirm "Have you mounted your partitions to /mnt?") {
        gum log -sl error "Cannot continue without mounting partitions."
        gum log -sl info "Please mount your partitions to /mnt and rerun the installer."
        exit 1
    }
}

def handle_copy_secrets [] {
    gum log -sl info "Copying secrets to the new filesystem."
    # TODO: some permission handling is probably necessary here
    let success = run-external-success rsync "-r" /run/plate/secrets/ /mnt/
    if not $success {
        gum log -sl error "Failed to copy secrets to the new filesystem."
        exit 1
    } else {
        gum log -sl info "Secrets copied successfully."
    }
}

def handle_sbkeys [] {
    if ($config | get secureBoot) == null {
        return
    }
    let basePath = $"/mnt($config | get secureBoot.pkiBundle)"
    if ($basePath | path exists) {
        gum log -sl info "Secure Boot keys are setup."
        return
    }
    gum log -sl warn "Secure Boot is enabled, but keys were not deployed. Generating new ones."
    let success = run-external-success sbctl create-keys "-d" $basePath "-e" $"($basePath)/keys"
    if not $success {
        gum log -sl warn "Failed to generate Secure Boot keys. Installation may fail."
    }
}

def handle_hardware_config [] {
    if (confirm "Does the provided system closure include the hardware configuration?") {
        let res = nixos-generate-config --root /mnt --show-hardware-config --no-filesystems | complete
        if $res.exit_code != 0 {
            gum log -sl error "Cannot determine the hardware configuration for the current system. This is likely indicative of a larger error."
            exit 1
        }
        let bootLines = $res.stdout | lines | where $it =~ '^\s*boot\.'
        let generatedBootConfig = nix eval --expr ('{' + ($bootLines | str join "\n") + '}') --json | from json
        let keysToCheck = ['initrd.availableKernelModules', 'initrd.kernelModules', 'kernelModules', 'extraModulePackages']
        if ($keysToCheck | any { |key|
            let cpath = $key | split row '.' | into cell-path
            not (check_subset ($config | get boot | get $cpath) ($generatedBootConfig | get boot | get $cpath))
        }) {
            gum log -sl warn "nixos-generate-config has detected additional kernel modules that are not present in your config. Your system may not boot successfully."
            if (confirm "Do you want to continue with the specified configuration anyway?") {
                return $system
            } else {
                exit 1
            }
        }
        return $system
    }
    gum log -sl info "Building an updated system closure."
    let extraArgs = if (confirm "Does your configuration already include disk configuration?") {
        ['--no-filesystems']
    } else {
        []
    }
    nixos-generate-config --root /mnt ...$extraArgs --show-hardware-config | save -f /run/plate/hardware-config.nix
    let new_system = nix build --print-out-paths --no-link --impure --expr $"\(\(builtins.getFlake ''($flake_source)''\).nixosConfigurations.\"($config | get outputName)\".extendModules {modules=[/run/plate/hardware-config.nix];}\).config.system.build.toplevel" | complete
    if $new_system.exit_code != 0 {
        gum log -sl error "Failed to build the updated system closure. Installation cannot proceed."
        exit 1
    }
    gum log -sl warn "Updated system build. You will need to adjust your own configuration to include the hardware configuration before rebuilding."
    $new_system.stdout | str trim
}

def handle_install [system: string] {
    gum log -sl info "Installing NixOS."
    let success = run-external-success nixos-install "--no-root-passwd" "--no-channel-copy" "--system" $system
    if not $success {
        gum log -sl error "Failed to install NixOS."
        exit 1
    }
    gum log -sl info "NixOS installed successfully. Copying your Flake to the new system."
    try {
        do -c {
            nix flake archive --to 'local?root=/mnt&require-sigs=false' $flake_source
            rm -rf /mnt/etc/nixos
            rsync -a $flake_source /mnt/etc/nixos
        }
    } catch {
        gum log -sl warn "Failed to copy your Flake to the new system. You may not be able to rebuild your system."
    }
}

def handle_home_manager [] {
    for it in ($config.homeManager.profiles) {
        gum log -sl info $"Copying Home-Manager profile for ($it.user) to installation."
        try {
            do -c {
                nix copy --to 'local?root=/mnt&require-sigs=false' $it.profile
                gum log -sl info $"Linking activation for Home-Manager profile for ($it.user). Run ~/activate upon first login."
                nixos-enter -c $"/run/current-system/sw/bin/su ($it.user) -s /run/current-system/sw/bin/bash -c 'ln -s ($it.profile)/activate ~/activate'"
            }
        } catch {
            gum log -sl error $"Failed to install Home-Manager profile for ($it.user)."
        }
    }
}

def handle_unmount [] {
    let success = run-external-success umount "-Rv" "/mnt/"
    if not $success {
        gum log -sl warn "Failed to unmount the new system."
        return
    }
    let success = run-external-success zpool export "-a"
    if not $success {
        gum log -sl warn "Failed to export ZFS pools. This may cause a warning on the next boot, but should not affect the system."
    }
}

def handle_reboot [] {
    gum log -sl info "Installation complete."
    if (confirm "Do you want to reboot now?") {
        systemctl reboot
    }
}

# -----------------------------------------------------------------------------
# Execution

# TODO: make a check that the terminal is compatible wtih gum?

def main [] {
    handle_root
    handle_workdir
    handle_secrets
    handle_partitioning
    handle_copy_secrets
    handle_sbkeys
    let system = handle_hardware_config
    handle_install $system
    handle_home_manager
    handle_unmount
    handle_reboot
}