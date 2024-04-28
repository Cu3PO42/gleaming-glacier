#!/usr/bin/env nu

# TODO: possibly handle disko encryption better / add consistency checks

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
# Input Helpers

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

def confirm [message: string] {
    run-external-success gum confirm $message
}

# -----------------------------------------------------------------------------
# Flake Helpers

def resolve_flake_url [url: string] {
    let res = nix flake metadata $url --json | complete
    if $res.exit_code != 0 {
        gum log -sl error $"The flake URL ($url) could not be resolved."
        exit 1
    }
    $res.stdout | from json | get url
}

def parse_flake [ref: string] {
    let parts = $ref | split row "#"
    if (($parts | length) != 2) {
        gum log -sl error $"($ref) is an invalid reference. It should contain exactly one '#'"
    }
    { url: (resolve_flake_url ($parts.0)), output: ($parts.1) }
}

def read_plate_config [target: record] {
    let plateConfig = do { nix eval --json $"($target | get url)#copperConfig.\"($target | get output)\".plate" } | complete
    if $plateConfig.exit_code != 0 {
        gum log -sl warn "Unable to determine your system's Plate configuration. Further errors may occur."
        gum log -sl error $plateConfig.stderr
        return null
    }
    if $plateConfig == null {
        gum log -sl warn "Your system is not configured for Plate."
    }
    $plateConfig.stdout | from json
}

def read_home_configs [url: string] {
    let res = nix eval --impure --json --expr $"builtins.attrNames \(\(builtins.getFlake \"($url)\"\).homeConfigurations or {}\)" | complete
    if $res.exit_code != 0 {
        gum log -sl warn $"Unable to determine your Home configurations. Home-Manager configs will not be included."
        return []
    }
    $res.stdout | from json
}

# -----------------------------------------------------------------------------
# OP Helpers

def read_op [ref: string] {
    let res = op read $ref | complete
    if $res.exit_code != 0 {
        gum log -sl error $"Could not read the reference ($ref) via 1Password."
        exit 1
    }
    $res.stdout
}

def read_op_key [ref: string] {
    # Fix up 1Password's weird handling of SSH keys over the CLI.
    let correctedRef = if ($ref | str ends-with "private key") {
        $"($ref)?ssh-format=openssh"
    } else {
        $ref
    }
    read_op $correctedRef | dos2unix
}

# -----------------------------------------------------------------------------
# Gathering phase

def clone_flake [flake_url: string, out: string] {
    gum log -sl info "Cloning your Flake."
    if (($flake_url | str starts-with 'git+file://') and not ($flake_url | str contains '?')) {
        # If the flake is local, it may have changes that are not committed...
        # However, if it contains a '?', it has a revision and is clean.
        cp -r ($flake_url | str substring 11..) $"($out)/flake"
    } else {
        nix flake clone $flake_url --dest $"($out)/flake"
    }
}

def encrypt_secrets [secrets_folder: string, out: string] {
    gum log -sl info "Generating SSH key pair for secret encryption. You most provide a password."
    let pw = input_confirm "encryption password" "Passwords"
    let generated = (ssh-keygen -t ed25519 -f $"($out)/age_key" -N $pw out+err> /dev/null | complete).exit_code == 0
    if not $generated {
        gum log -sl error "Failed to generate SSH key pair."
        exit 1
    }
    gum log -sl info "Encrypting secrets with SSH key pair."
    do {
        cd $secrets_folder
        tar -c .
    } | age -r (open $"($out)/age_key.pub") out> $"($out)/secrets.tar.age"
}

def gather_secrets [plateConfig, out: string] {
    if $plateConfig == null {
        gum log -sl warn "No secrets will be included in the installer image. Do you wish to continue anyway?"
        if (confirm "Do you wish to continue with a standard configuration anyway?") {
            return
        } else {
            exit 1
        }
    }

    let opEnv = if $plateConfig.opAccount != null {
        { OP_ACCOUNT: $plateConfig.opAccount }
    } else { {} }
    with-env $opEnv {
        if $plateConfig.hostKey != null {
            ^mkdir -p $"($out)($plateConfig.hostKeyLocation | path dirname)"
            read_op_key $plateConfig.hostKey | save $"($out)($plateConfig.hostKeyLocation)"
        }

        if $plateConfig.diskEncryptionKey != null {
            ^mkdir -p $"($out)/tmp"
            read_op $plateConfig.diskEncryptionKey | save $"($out)/tmp/dek.key"
        }
    }

    if $plateConfig.secureBootKeys != null {
        ^mkdir -p $"($out)($plateConfig.secureBootKeyLocation)"
        do {
            cd $"($out)($plateConfig.secureBootKeyLocation)"
            read_op $plateConfig.secureBootKeys | tar -x
        }
    }

    # TODO: potentially secure boot keys down the line
}

def select_home_config [target: record, user: string, available: list] {
    let config_name = if ($available | any {|| $in == $user}) {
        $user
    } else if ($available | any {|| $in == $"($user)@($target.output)"}) {
        $"($user)@($target.output)"
    } else {
        gum log -sl warn $"Home Configurition for user ($user) not found."
        return null
    }
    $config_name
}

def collect_home_configs [target: record, plateConfig: record] {
    let available = read_home_configs $target.url
    $plateConfig.standaloneHomeManagerUsers | each {{ user: $in, attribute: (select_home_config $target $in $available) }} | filter { $in.attribute != null }
}

def build_image [target: record, installer: record, homeConfigs: list, extraContent: record] {
    gum log -sl info "Building the modified installer."
    let builder = (nix build --no-link --print-out-paths --impure --expr $"
    let
        flake = builtins.getFlake ''($target | get url)'';
    in import @BUILDER_NIX@ {
        installerSystem = \(builtins.getFlake ''($installer | get url)''\).nixosConfigurations.\"($installer | get output)\";
        targetFlake = flake;
        targetSystem = flake.nixosConfigurations.\"($target | get output)\";
        outputName = ''($target | get output)'';
        homeConfigs = builtins.fromJSON ''($homeConfigs | to json)'';
        plate-installer = @PLATE_INSTALLER@;
    }")
    if ($builder | str trim | is-empty) {
        gum log -sl error "Could not generate image builder."
        exit 1
    }
    let entries = $extraContent | transpose key val
    gum log -sl info "Building installer image."
    let prior_dir = pwd
    let build_dir = "tmp.plate-bake"
    mkdir $build_dir
    do {
        cd $build_dir
        let success = with-env {
            extraSources: ($entries | each {$in | get val} | str join ":"),
            extraTargets: ($entries | each {$in | get key} | str join ":"),
        } { run-external-success $builder }
        if not $success {
            gum log -sl error "Failed to build installer ISO image."
            exit 1
        }

        mkdir $"($prior_dir)/iso"
        mv ./iso/* $"($prior_dir)/iso"
    }
    rm -rf $build_dir
}

# -----------------------------------------------------------------------------
# Execution

def main [
    --target: string # The system configuration you want to install eventually.
    --installer: string # The installer image
] {
    let parsedTarget = parse_flake $target
    let parsedInstaller = parse_flake $installer
    let plateConfig = read_plate_config $parsedTarget

    let tmp = mktemp -d

    let secrets = mktemp -d
    gather_secrets $plateConfig $secrets
    if (ls $secrets | length) > 0 {
        encrypt_secrets $secrets $tmp
    }
    rm -rf $secrets

    clone_flake ($parsedTarget | get url) $tmp

    let homeConfigs = collect_home_configs $parsedTarget $plateConfig

    let extraPaths = ls $tmp | get name | path basename | each {{/plate/($in): $"($tmp)/($in)"}} | reduce {|it, acc| {...$acc, ...$it}}
    build_image $parsedTarget $parsedInstaller $homeConfigs $extraPaths

    rm -rf $tmp
}
