{origin, ...}: {
  imports = [
    origin.inputs.comin.nixosModules.default
  ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/Cu3PO42/gleaming-glacier.git";
        branches.main.name = "deploy";
      }
    ];
  };
}
