{ haskell, makeWrapper, runCommand, extraPackagesFun ? ps: [ ], writeShellScriptBin, bubblewrap, lib, util-linux }:
let
  web-ghc-server = haskell.packages.web-ghc.components.exes.web-ghc-server;

  runtimeGhc = haskell.project.ghcWithPackages (ps: [
    ps.playground-common
    ps.plutus-core
    ps.plutus-tx
    ps.plutus-contract
    ps.plutus-ledger
  ] ++ (extraPackagesFun ps));

  runtimeGhcWrapped = writeShellScriptBin "runghc" ''
    export PATH=$PATH:${lib.makeBinPath [ bubblewrap runtimeGhc util-linux ]}
    echo $PATH 
    echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    exec setpriv --ambient-caps -all -- \
      bwrap --ro-bind /nix /nix --ro-bind /proc /proc --dev /dev --ro-bind "''${@: -1}" "''${@: -1}" --unshare-all -- \
      runghc "$@"
  '';
in
runCommand "web-ghc" { buildInputs = [ makeWrapper ]; } ''
  # We need to provide the ghc interpreter with the location of the ghc lib dir and the package db
  mkdir -p $out/bin
  ln -s ${web-ghc-server}/bin/web-ghc-server $out/bin/web-ghc-server
  wrapProgram $out/bin/web-ghc-server --set GHC_BIN_DIR ${runtimeGhc}/bin
''
