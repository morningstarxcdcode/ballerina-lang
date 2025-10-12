#!/usr/bin/env python3
import re

with open('anonymous_type_npe_fix_documentation.md', 'r') as f:
    content = f.read()

# Add blank lines around headings
content = re.sub(r'(\n)(##+ [^\n]+)', r'\1\n\2', content)
content = re.sub(r'(##+ [^\n]+)(\n)', r'\1\n\n\2', content)

# Add blank lines around lists
content = re.sub(r'(\n)([-*+] [^\n]+)', r'\1\n\2', content)

# Add blank lines around fenced code blocks
content = re.sub(r'(\n)(```)', r'\1\n\2', content)
content = re.sub(r'(```)(\n)', r'\1\n\n\2', content)

# Fix inline HTML
content = re.sub(r'<parameter name="filePath">', r'`filePath` parameter', content)

with open('anonymous_type_npe_fix_documentation.md', 'w') as f:
    f.write(content)