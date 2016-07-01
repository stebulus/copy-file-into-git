{ cabal-install
, ghcWithPackages
, stdenv }:
let ghc = ghcWithPackages (pkgs: with pkgs; [
    gitlib
    gitlib-libgit2
]);
in stdenv.mkDerivation {
    name = "giths-0.1.0";
    buildInputs = [ ghc cabal-install ];
}
