with import <nixpkgs> {};
callPackage (import ./default.nix) {
    ghcWithPackages = haskellPackages.ghcWithHoogle;
}
