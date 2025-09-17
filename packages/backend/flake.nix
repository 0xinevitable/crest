{
  description = "TypeScript Backend Development Environment with SQLite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js and package managers
            nodejs_22
            nodePackages.npm
            nodePackages.yarn
            nodePackages.pnpm

            # TypeScript toolchain
            nodePackages.typescript
            nodePackages.ts-node
            nodePackages.typescript-language-server

            # SQLite and database tools
            sqlite
            sqlite-interactive
            sqlitebrowser

            # Development tools
            nodePackages.nodemon
            nodePackages.prettier

            # System tools
            git
            curl
            jq

            # Optional: Database migration tools
            nodePackages.prisma
          ];

          shellHook = ''
            echo "🚀 TypeScript Backend Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📦 Node.js: $(node --version)"
            echo "📦 npm: $(npm --version)"
            echo "📦 TypeScript: $(tsc --version)"
            echo "🗃️  SQLite: $(sqlite3 --version)"
            echo ""
            echo "💡 Available commands:"
            echo "  npm init -y           # Initialize package.json"
            echo "  npm install <pkg>     # Install packages"
            echo "  npm run dev           # Start development server"
            echo "  sqlite3 <db>          # Open SQLite database"
            echo "  sqlitebrowser         # GUI database browser"
            echo ""
            echo "🔧 Development tools ready!"
          '';

          # Environment variables
          env = {
            DATABASE_URL = "file:./database.db";
            NODE_ENV = "development";
          };
        };
      }
    );
}
