#!/bin/bash
set -e

DOMAINS_FILE="domains.txt"
SOURCE="template.tpl"
OUTPUT="template.built.tpl"

if [ ! -f "$DOMAINS_FILE" ]; then
  echo "Error: $DOMAINS_FILE not found."
  echo "Create it with one analytics domain per line, e.g.: analytics.example.com"
  exit 1
fi

python3 - "$DOMAINS_FILE" "$SOURCE" "$OUTPUT" << 'EOF'
import sys

domains_file, source_file, output_file = sys.argv[1], sys.argv[2], sys.argv[3]

domains = []
with open(domains_file) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#'):
            domains.append(line)

if not domains:
    print("Warning: no domains found in domains.txt — output will be identical to source.")

entries = ''
for domain in domains:
    entries += (
        ',\n              {\n'
        '                "type": 1,\n'
        '                "string": "https://' + domain + '/"\n'
        '              }'
    )

with open(source_file) as f:
    content = f.read()

MARKER = '"https://*.piwik.pro/"'
if MARKER not in content:
    print("Error: could not find injection point in template.tpl.")
    sys.exit(1)

content = content.replace(MARKER, MARKER + entries, 1)

with open(output_file, 'w') as f:
    f.write(content)

print(f"Built {output_file} with {len(domains)} custom domain(s).")
EOF
