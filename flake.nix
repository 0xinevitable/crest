{
  description = "Crest";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js ecosystem
            nodejs
            yarn
            prisma-engines
            
            # Development tools
            git
            podman
            podman-compose
            
            # Database tools
            postgresql
            
            # Optional: useful development utilities
            jq
            curl
            wget
          ];

          shellHook = ''
            export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
            export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
            export PATH="$PWD/node_modules/.bin/:$PATH"

            echo "🚀 Crest development environment loaded!"
            echo "Node.js: $(node --version)"
            echo "Yarn: $(yarn --version)"
          '';

          NODE_ENV = "development";
        };
      });
}