{
  description = "Crest - Node.js development environment";

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
            
            # Development tools
            git
            docker
            docker-compose
            
            # Database tools
            mysql80
            
            # System utilities
            gnumake
            gcc
            python3
            
            # Optional: useful development utilities
            jq
            curl
            wget
          ];

          shellHook = ''
            echo "🚀 Crest development environment loaded!"
            echo "Node.js: $(node --version)"
            echo "Yarn: $(yarn --version)"
            echo ""
            echo "Available commands:"
            echo "  yarn install    - Install dependencies"
            echo "  yarn dev        - Start development server"
            echo "  docker-compose  - Manage containers"
            echo ""
          '';

          # Environment variables
          NODE_ENV = "development";
          
          # Fix for some Node.js packages that need Python
          PYTHON = "${pkgs.python3}/bin/python";
        };
      });
}