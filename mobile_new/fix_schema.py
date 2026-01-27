import os

file_path = r'c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new\supabase_schema.sql'
temp_path = file_path + '.tmp'

with open(file_path, 'rb') as f:
    content = f.read()

# Remove null bytes if present (common in UTF-16 misreads)
content = content.replace(b'\x00', b'')

# Decode to string
try:
    text = content.decode('utf-8')
except UnicodeDecodeError:
    text = content.decode('latin-1')

lines = text.splitlines()

# Remove extra empty lines (if every second line is empty)
cleaned_lines = []
for i, line in enumerate(lines):
    # If the file had double spacing, we might want to skip empty lines 
    # but only if they are the "extra" ones.
    # However, some empty lines might be intentional.
    # A safer way is to just strip trailing whitespace and see if it's empty.
    if line.strip() or (i > 0 and lines[i-1].strip()):
        cleaned_lines.append(line.rstrip())

# Further cleaning: 
# 1. Replace \$\$ with $$
final_text = '\n'.join(cleaned_lines)
final_text = final_text.replace(r'\$\$', '$$')

# Save to temp file
with open(temp_path, 'w', encoding='utf-8') as f:
    f.write(final_text)

print(f"Cleaned file written to {temp_path}")
