#!/usr/bin/env bash
# Builds the reference docs of every package the index lists into the site
# folder given (the gh-pages branch's files), each version tag once:
#
#   <site>/<domain>/<owner>/<name>/<version>/   one tag's docs
#   <site>/<domain>/<owner>/<name>/             versions.json, index.html, latest/
#   <site>/built.json                            "<source> <version>" -> commit
#   <site>/index.html                            every package, linked
#
# `pepper doc package` only parses a package (no build script, no [native],
# no compile) and shows what it wrote as text, never HTML, so no package's
# code runs and no package's page can script another's. Each build is
# bounded in time and size. A tag moved to another commit keeps its first
# build and is reported. A tag that does not document gets a page saying so.
#
# Usage: scripts/build-docs.sh <site-folder> [--rebuild]
#   --rebuild   build every version again (after the renderer changes)
set -euo pipefail

site="$(realpath -m "$1")"
rebuild="${2:-}"
base="${PACKAGE_DOCS_BASE:-https://pepper-lang.dev/index}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$site"
built="$site/built.json"
[ -f "$built" ] || echo '{}' > "$built"
[ "$rebuild" = --rebuild ] && echo '{}' > "$built"

# The domain of a source's host: github, gitlab or codeberg.
domain_of() {
    case "$1" in
        github) echo github.com ;;
        gitlab) echo gitlab.com ;;
        codeberg) echo codeberg.org ;;
        *) return 1 ;;
    esac
}

# A page that says why a version has no docs.
failed_page() {
    local dir="$1" title="$2" reason="$3"
    mkdir -p "$dir"
    {
        echo '<!doctype html><meta charset="utf-8">'
        echo "<title>$title: no docs</title>"
        echo "<h1>$title</h1><p>The docs of this version did not build: $reason.</p>"
        echo "<p>See the index's <code>docs</code> workflow run for the log.</p>"
    } > "$dir/index.html"
}

failures=0
packages=()
for file in packages/*.toml; do
    name="$(basename "$file" .toml)"
    source="$(sed -nE 's/^source *= *"([a-z]+):([A-Za-z0-9._-]+\/[A-Za-z0-9._-]+)".*/\1 \2/p' "$file" | head -1)"
    if [ -z "$source" ]; then
        echo "::warning file=$file::no source the docs site can read"
        continue
    fi
    host="${source%% *}"
    repository="${source#* }"
    domain="$(domain_of "$host")" || { echo "::warning file=$file::unknown host '$host'"; continue; }
    url="https://$domain/$repository.git"
    packages+=("$name $domain/$repository")
    # Each version tag (vX.Y.Z), newest commits listed as git does.
    tags="$(git ls-remote --tags --refs "$url" 'v*' 2>/dev/null || true)"
    while read -r commit ref; do
        [ -n "$ref" ] || continue
        tag="${ref#refs/tags/}"
        version="${tag#v}"
        [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || continue
        key="$host:$repository $version"
        recorded="$(jq -r --arg k "$key" '.[$k] // ""' "$built")"
        if [ -n "$recorded" ]; then
            if [ "$recorded" != "$commit" ]; then
                echo "::warning::$key moved from $recorded to $commit; keeping the first build"
            fi
            continue
        fi
        out="$site/$domain/$repository"
        clone="$work/$name-$version"
        echo "=== $name $version ($commit)"
        if ! timeout 120 git clone --quiet --depth 1 --branch "$tag" "$url" "$clone"; then
            failed_page "$out/$version" "$name $version" "the tag could not be cloned"
            failures=$((failures + 1))
        else
            # The package's own .pep folder never takes part, and no symlink
            # can point the build at a file of this machine.
            rm -rf "$clone/.pep"
            find "$clone" -type l -delete
            if (cd "$clone" && timeout 300 pepper doc package --site "$out" --docs-base "$base"); then
                size="$(du -sm "$out/$version" | cut -f1)"
                if [ "$size" -gt 50 ]; then
                    rm -rf "$out/$version"
                    failed_page "$out/$version" "$name $version" "its docs are over 50 MB"
                    failures=$((failures + 1))
                fi
            else
                failed_page "$out/$version" "$name $version" "pepper doc package failed"
                failures=$((failures + 1))
            fi
        fi
        rm -rf "$clone"
        jq --arg k "$key" --arg c "$commit" '.[$k] = $c' "$built" > "$built.new" && mv "$built.new" "$built"
    done <<< "$tags"
done

# The front page: every package, linked to its docs.
{
    echo '<!doctype html><meta charset="utf-8"><title>Pepper package docs</title>'
    echo '<h1>Pepper package docs</h1>'
    echo '<p>The reference of every package in the <a href="https://pepper-lang.dev/packages.html">package index</a>, by version.</p><ul>'
    for entry in "${packages[@]}"; do
        name="${entry%% *}"
        path="${entry#* }"
        if [ -f "$site/$path/versions.json" ]; then
            echo "<li><a href=\"$path/\">$name</a></li>"
        else
            echo "<li>$name: no version tag documented yet</li>"
        fi
    done
    echo '</ul>'
} > "$site/index.html"
touch "$site/.nojekyll"
echo "built; $failures version(s) did not document"
