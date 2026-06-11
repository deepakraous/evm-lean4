{ pkgs }: pkgs.mkShell {
  buildInputs = [
    pkgs.lean
    pkgs.git
    pkgs.curl
  ];

  shellHook = ''
    echo "Repl.it ready: run 'lake build' or 'lake run'"
  '';
}
