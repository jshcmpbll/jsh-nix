{ stdenvNoCC, lib, python3, python3Packages, copyPathToStore, }:
python3Packages.buildPythonPackage rec {
  pname = "finvizrec";
  version = "0.0.1";

  src = ./.;

  format = "setuptools";

  propagatedBuildInputs = [ python3Packages.finvizfinance ];
}
