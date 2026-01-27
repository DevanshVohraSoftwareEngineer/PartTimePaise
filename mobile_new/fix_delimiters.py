import os

file_path = r'c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new\supabase_schema.sql'

with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Replace \$\$ with $$
cleaned_content = content.replace('\\$\\$', '$$')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(cleaned_content)

print("Replacement complete.")
