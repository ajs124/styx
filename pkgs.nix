let
  lock = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile (toString ./flake.lock)));

  inputs = {
    nixpkgs = import (builtins.fetchTree lock.nodes.nixpkgs.locked) {};
    self = ./.;
  };

  cell = {};
in
  inputs.nixpkgs.extend (_: _: {
    inherit
      (import ./src/app/cli.nix {inherit inputs cell;})
      styx
      ;
  })
