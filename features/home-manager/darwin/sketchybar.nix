{lib, config, pkgs, ...}: with lib; let
  cfg = config.copper.feature.darwin.sketchybar;

  helpers = pkgs.stdenv.mkDerivation {
    name = "sketchybar-helpers";
    src = ../../../config/sketchybar-neo/helpers;
    installPhase = ''
      mkdir -p $out
      find . -type f -executable -exec cp --parents -t $out/ {} +
    '';
  };

  # Upstream luaposix package is out of date and does not build with Lua 5.4
  luaposix = pkgs.lua54Packages.callPackage (
    {
      bit32,
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaAtLeast,
      luaOlder,
    }:
    buildLuarocksPackage {
      pname = "luaposix";
      version = "36.3-1";
      knownRockspec =
        (fetchurl {
          url = "mirror://luarocks/luaposix-36.3-1.rockspec";
          sha256 = "0jwah6b1bxzck29zxbg479zm1sqmg7vafh7rrkfpibdbwnq01yzb";
        }).outPath;
      src = fetchzip {
        url = "http://github.com/luaposix/luaposix/archive/v36.3.zip";
        hash = "sha256-RKDH1sB7r7xDqueByWwps5fBfl5GBL9L86FjzfStBUw=";
      };

      disabled = luaOlder "5.1" || luaAtLeast "5.5";
      propagatedBuildInputs = [ bit32 ];

      meta = {
        homepage = "http://github.com/luaposix/luaposix/";
        description = "Lua bindings for POSIX";
        maintainers = with lib.maintainers; [ lblasc ];
        license.fullName = "MIT/X11";
      };
    }
  ) { };
in {
  featureOptions = {
    implementation = mkOption {
      type = types.enum ["bash" "lua"];
      default = "lua";
      description = "Which of my two sketchybar configurations to set up.";
    };
  };

  config = {};

  imports = [
    (mkIf (cfg.implementation == "bash") {
      copper.file.config."sketchybar" = "config/sketchybar";
    })
    (mkIf (cfg.implementation == "lua") (let
      # since luaposix is not supported in Lua 5.5, we need to downgrade to 5.4
      lua = pkgs.lua5_4.withPackages (ps: [
        luaposix
        ps.cjson
        (pkgs.sbarlua.override {lua55Packages = pkgs.lua54Packages;})
      ]);
    in {
      xdg.configFile."sketchybar/sketchybarrc" = {
        text = ''
          #!${getExe lua}

          -- Add the impl directory so the rest of the imports line up
          local USER = os.getenv("USER")
          package.path = package.path .. ";/Users/" .. USER .. "/.config/sketchybar/impl/?.lua;/Users/" .. USER .. "/.config/sketchybar/impl/?/init.lua"

          -- Load the main implementation
          require("./impl/sketchybarrc")
        '';
        executable = true;
      };
      home.file.".local/bin/sketchybar-helpers".source = helpers;
      copper.file.config."sketchybar/impl" = "config/sketchybar-neo";
    }))
  ];
}
