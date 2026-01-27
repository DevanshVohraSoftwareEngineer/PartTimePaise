import re
import os

file_path = r'c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new\supabase_schema.sql'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Fix encoding issues briefly (replace the replacement char with something sensible if possible, or just leave as is)
# The user's file has '' which is the replacement character.
# We'll try to restore common emojis if we can detect them, but mainly we fix the views.

def add_drop_view(match):
    view_name = match.group(2)
    full_match = match.group(0)
    # Check if 'drop view' is already present in the preceding few lines
    # For simplicity, we just always add it. It's idempotent anyway.
    return f"drop view if exists {view_name} cascade;\n\n{full_match}"

# Pattern to find 'create or replace view [name]'
# Group 1: optional 'public.'
# Group 2: view name
pattern = re.compile(r'(?i)create\s+or\s+replace\s+view\s+(?:public\.)?(\w+)', re.MULTILINE)

# We want to avoid adding multiple drops if they are already there.
# But adding them multiple times doesn't hurt.
# Let's do a more careful replacement.

lines = content.split('\n')
new_lines = []
for i, line in enumerate(lines):
    match = pattern.search(line)
    if match:
        view_name = match.group(1)
        # Check if previous lines already have a drop
        has_drop = False
        for j in range(max(0, i-5), i):
            if f'drop view if exists {view_name}' in lines[j].lower():
                has_drop = True
                break
        if not has_drop:
            new_lines.append(f"drop view if exists public.{view_name} cascade;")
    new_lines.append(line)

final_content = '\n'.join(new_lines)

# Fix common corrupted strings found in logs
final_content = final_content.replace('x      Chat secure', '🔒 Chat secure')
final_content = final_content.replace('x a   Working on it', '🚀 Working on it')
final_content = final_content.replace('S &  Deal closed', '✅ Deal closed')
final_content = final_content.replace('R  Task cancelled', '❌ Task cancelled')
final_content = final_content.replace('', '') # Remove remaining replacement chars

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(final_content)

print("Fix completed.")
