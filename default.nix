{ cabal-install
, ghcWithPackages
, stdenv }:
let ghc = ghcWithPackages (pkgs: with pkgs; [ text ]);
in stdenv.mkDerivation {
    name = "giths-0.1.0";
    buildInputs = [ ghc cabal-install ];
}
