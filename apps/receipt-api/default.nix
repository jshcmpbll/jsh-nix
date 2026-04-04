{ stdenv, lib, rustPlatform, postgresql, pkg-config }:

let
  manifestPath = ./Cargo.toml;
in
rustPlatform.buildRustPackage rec {
  pname = "receipt-api";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ postgresql ];

  meta = with lib; {
    description = "A Rust API service for managing receipt data with PostgreSQL";
    homepage = "https://github.com/jshcmpbll/jsh-nix";
    license = licenses.mit;
    mainProgram = "receipt-api";
  };
}
