#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-public}"

if [ ! -d "$ROOT_DIR" ]; then
  echo "Directory not found: $ROOT_DIR" >&2
  exit 1
fi

human_size() {
  local bytes=$1
  if [ "$bytes" -ge 1073741824 ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1f GB", b / 1073741824 }'
  elif [ "$bytes" -ge 1048576 ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1f MB", b / 1048576 }'
  elif [ "$bytes" -ge 1024 ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1f KB", b / 1024 }'
  else
    printf "%d B" "$bytes"
  fi
}

generate_index() {
  local dir="$1"
  local title="${dir#$ROOT_DIR}"
  title="${title#/}"
  [ -z "$title" ] && title="/"

  cat > "$dir/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Index of $title</title>
<style>
  body { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; margin: 2rem; color: #24292f; background: #fff; }
  h1 { font-size: 1.15rem; padding-bottom: .6rem; border-bottom: 1px solid #d0d7de; }
  table { width: 100%; border-collapse: collapse; }
  th, td { text-align: left; padding: .35rem .75rem; }
  tr:nth-child(even) { background: #f6f8fa; }
  a { color: #0969da; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .footer { margin-top: 2rem; padding-top: .6rem; border-top: 1px solid #d8dee4; color: #57606a; font-size: .8rem; }
</style>
</head>
<body>
<h1>Index of $title</h1>
<table>
<tr><th>Name</th><th>Size</th><th>Date</th></tr>
EOF

  if [ "$dir" != "$ROOT_DIR" ]; then
    echo '<tr><td><a href="../index.html">../</a></td><td>-</td><td>-</td></tr>' >> "$dir/index.html"
  fi

  while IFS= read -r -d '' subdir; do
    local name date
    name=$(basename "$subdir")
    date=$(stat -c '%y' "$subdir" 2>/dev/null | cut -d' ' -f1)
    printf '<tr><td><a href="%s/index.html">%s/</a></td><td>-</td><td>%s</td></tr>\n' "$name" "$name" "$date" >> "$dir/index.html"
  done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

  while IFS= read -r -d '' file; do
    local name size date
    name=$(basename "$file")
    [ "$name" = "index.html" ] && continue
    size=$(stat -c '%s' "$file" 2>/dev/null)
    date=$(stat -c '%y' "$file" 2>/dev/null | cut -d' ' -f1)
    printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td></tr>\n' "$name" "$name" "$(human_size "$size")" "$date" >> "$dir/index.html"
  done < <(find "$dir" -maxdepth 1 -mindepth 1 -type f -print0 | sort -z)

  cat >> "$dir/index.html" <<EOF
</table>
<div class="footer">&copy; <a href="https://orbitbits.com">OrbitBits</a></div>
</body>
</html>
EOF
}

while IFS= read -r -d '' dir; do
  generate_index "$dir"
done < <(find "$ROOT_DIR" -type d -print0 | sort -zr)

echo "Generated index.html in $(find "$ROOT_DIR" -name index.html | wc -l) directories"
