#!/bin/bash

# Script to update OCaml documentation in Docusaurus
# Can be run from project root or doc/ directory
# Usage: ./update-ocaml-docs.sh [--yes]

set -euo pipefail

# Parse command line arguments
AUTO_YES=false
if [[ "${1:-}" == "--yes" ]]; then
    AUTO_YES=true
fi

# Helper function for interactive prompts
prompt_user() {
    local message="$1"
    if [[ "$AUTO_YES" == "true" ]]; then
        echo "$message (Y/n) y"
        return 0
    fi

    echo -n "$message (Y/n) "
    read -r response
    case "$response" in
        [nN]|[nN][oO]) return 1 ;;
        *) return 0 ;;
    esac
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine project root and doc directory based on script location
# The script is always in doc/, so project root is one level up
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOC_DIR="$SCRIPT_DIR"

# Verify we have the correct directories
if [[ ! -f "$PROJECT_ROOT/dune-project" ]] || [[ ! -f "$DOC_DIR/docusaurus.config.ts" ]]; then
    echo "Error: Could not locate project structure relative to script location"
    echo "Expected: $PROJECT_ROOT/dune-project and $DOC_DIR/docusaurus.config.ts"
    exit 1
fi

echo "🔧 Updating OCaml documentation for Docusaurus..."
echo "   Project root: $PROJECT_ROOT"
echo "   Doc directory: $DOC_DIR"

# Step 1: Generate/check OCaml markdown documentation
echo "📚 Checking for OCaml documentation..."

# Check if files exist and offer to regenerate
if [[ -d "$PROJECT_ROOT/_build/default/_doc/_markdown" ]]; then
    file_count=$(find "$PROJECT_ROOT/_build/default/_doc/_markdown" -name "*.md" | wc -l)
    echo "   ✓ Found $file_count existing markdown files"

    echo ""
    if ! prompt_user "🔄 Regenerate OCaml documentation with dune build @doc-markdown?"; then
        echo "   Using existing documentation files."
    else
        echo "   📝 Regenerating OCaml documentation..."
        echo "   Running: dune build @doc-markdown"
        cd "$PROJECT_ROOT"
        if dune build @doc-markdown; then
            echo "   ✓ Documentation regenerated successfully"
            # Recount files after generation
            file_count=$(find "_build/default/_doc/_markdown" -name "*.md" | wc -l)
            echo "   ✓ Generated $file_count markdown files"
        else
            echo "   ⚠️  Documentation generation had some failures, checking results..."
            new_file_count=$(find "_build/default/_doc/_markdown" -name "*.md" 2>/dev/null | wc -l)
            if [[ $new_file_count -gt 0 ]]; then
                echo "   ✓ Found $new_file_count markdown files despite some failures"
                if ! prompt_user "Continue with partial documentation?"; then
                    echo "   ❌ Aborted by user"
                    exit 1
                fi
                file_count=$new_file_count
            else
                echo "   ❌ No documentation files generated"
                exit 1
            fi
        fi
    fi
else
    echo "   ⚠️  No generated documentation found"
    if ! prompt_user "Generate OCaml documentation with dune build @doc-markdown?"; then
        echo "   ❌ Aborted by user"
        exit 1
    fi

    echo "   📝 Generating OCaml documentation..."
    echo "   Running: dune build @doc-markdown"
    cd "$PROJECT_ROOT"
    if dune build @doc-markdown; then
        echo "   ✓ Documentation generated successfully"
        # Count files after generation
        if [[ -d "_build/default/_doc/_markdown" ]]; then
            file_count=$(find "_build/default/_doc/_markdown" -name "*.md" | wc -l)
            echo "   ✓ Generated $file_count markdown files"
        else
            echo "   ❌ Generation completed but no files found"
            exit 1
        fi
    else
        echo "   ⚠️  Documentation generation had some failures, checking results..."
        if [[ -d "_build/default/_doc/_markdown" ]]; then
            file_count=$(find "_build/default/_doc/_markdown" -name "*.md" | wc -l)
            if [[ $file_count -gt 0 ]]; then
                echo "   ✓ Found $file_count markdown files despite some failures"
                if ! prompt_user "Continue with partial documentation?"; then
                    echo "   ❌ Aborted by user"
                    exit 1
                fi
            else
                echo "   ❌ No documentation files generated"
                exit 1
            fi
        else
            echo "   ❌ Documentation generation failed completely"
            exit 1
        fi
    fi
fi

# Step 2: Reset and create target directory
echo ""
if ! prompt_user "📁 Reset and copy OCaml documentation to Docusaurus?"; then
    echo "   ❌ Aborted by user"
    exit 1
fi

echo "📁 Resetting target directory..."
echo "   Running: rm -rf $DOC_DIR/docs/reference/ocaml-api"
rm -rf "$DOC_DIR/docs/reference/ocaml-api"
echo "   Running: mkdir -p $DOC_DIR/docs/reference/ocaml-api"
mkdir -p "$DOC_DIR/docs/reference/ocaml-api"

# Step 3: Copy generated files
echo "📋 Copying generated markdown files..."
echo "   Running: cp -r $PROJECT_ROOT/_build/default/_doc/_markdown/* $DOC_DIR/docs/reference/ocaml-api/"
cp -r "$PROJECT_ROOT/_build/default/_doc/_markdown"/* "$DOC_DIR/docs/reference/ocaml-api/"

# Step 4: Set proper permissions (in case source files are read-only)
echo "🔐 Setting file permissions..."
echo "   Running: find $DOC_DIR/docs/reference/ocaml-api -type f -exec chmod 644 {} \;"
find "$DOC_DIR/docs/reference/ocaml-api" -type f -exec chmod 644 {} \;

echo "✅ OCaml documentation updated successfully!"
echo "   Files copied to: $DOC_DIR/docs/reference/ocaml-api/"

# Step 5: Optional build step
echo ""
if ! prompt_user "🚀 Build the Docusaurus site now?"; then
    echo "   ❌ Aborted by user"
    exit 1
fi

echo "🚀 Building Docusaurus site..."
echo "   Running: cd $DOC_DIR && npm run build"
cd "$DOC_DIR"
if npm run build; then
    echo ""
    echo "📖 Documentation site ready!"
    echo "   • For development (live reload): npm run start"
    echo "   • To serve built site: npm run serve"
    echo "   • Built files are in: $DOC_DIR/build/"
else
    echo ""
    echo "⚠️  Build failed, but documentation files were copied successfully."
    echo "   You can manually run 'npm run build' from the doc directory to debug."
fi
