
import re
import os

def clean_schema(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split into blocks based on standard SQL delimiters (semi-colon at end of line, or special headers)
    # This is naive; a better approach is to scan for specific headers or CREATE statements.
    
    # Strategy:
    # 1. Regex find all "CREATE TABLE", "CREATE OR REPLACE FUNCTION", "CREATE TRIGGER", "CREATE VIEW", "CREATE POLICY"
    # 2. Track seen items.
    
    # We want to preserve the structure but dedup specific named entities.
    # We will split the file into logical chunks.
    
    # Normalize line endings
    content = content.replace('\r\n', '\n')
    
    # We'll treat the file as a sequence of statements.
    # A statement roughly ends with ";\n"
    
    # Regex for identifying definitions
    # Capture group 1: Type (TABLE, FUNCTION, etc.)
    # Capture group 2: Name
    definition_pattern = re.compile(r'create\s+(or\s+replace\s+)?(table|function|trigger|view|policy)\s+(if\s+not\s+exists\s+)?("?[\w\.]+"?)\s', re.IGNORECASE)
    
    # We will perform a 2-pass scan.
    # Pass 1: Identify all definitions and their locations (start, end).
    # Pass 2: Filter out duplicates (keeping the LAST one).
    
    definitions = [] # List of {type, name, start, end, full_match}
    
    # We need to parse statements carefully.
    # Let's split by top-level semicolons. 
    # Use a simple parser that ignores semicolons inside $$, '', ""
    
    statements = []
    current_stmt_start = 0
    in_dollar_quote = False
    in_single_quote = False
    dollar_tag = ''
    
    i = 0
    length = len(content)
    while i < length:
        char = content[i]
        
        # Check Dollar Quotes $$ or $tag$
        if char == '$' and not in_single_quote:
            # Check if it is a tag start/end
            match = re.match(r'\$([a-zA-Z0-9_]*)\$', content[i:])
            if match:
                tag = match.group(0)
                if not in_dollar_quote:
                    in_dollar_quote = True
                    dollar_tag = tag
                    i += len(tag) - 1
                elif in_dollar_quote and tag == dollar_tag:
                    in_dollar_quote = False
                    dollar_tag = ''
                    i += len(tag) - 1
        
        # Check Single Quotes '
        elif char == "'" and not in_dollar_quote:
            in_single_quote = not in_single_quote
            
        # Check Statement End ;
        elif char == ';' and not in_dollar_quote and not in_single_quote:
            # End of statement
            stmt_end = i + 1
            stmt_text = content[current_stmt_start:stmt_end]
            statements.append({'start': current_stmt_start, 'end': stmt_end, 'text': stmt_text})
            current_stmt_start = stmt_end
            
            # Skip whitespace/newlines after semicolon
            while current_stmt_start < length and content[current_stmt_start].isspace():
                current_stmt_start += 1
            i = current_stmt_start - 1 # Adjust for loop increment
            
        i += 1
        
    # Append last statement if any
    if current_stmt_start < length:
        statements.append({'start': current_stmt_start, 'end': length, 'text': content[current_stmt_start:]})

    print(f"Parsed {len(statements)} statements.")
    
    # Now analyze statements for duplicates
    # Map (type, name) -> [indices]
    definition_map = {}
    
    final_statements = []
    
    # Keep track of indices to remove
    to_remove = set()
    
    for idx, stmt in enumerate(statements):
        text = stmt['text'].strip()
        
        # Check regex
        match = definition_pattern.search(text)
        if match:
            obj_type = match.group(2).lower()
            obj_name = match.group(4).lower()
            
            # Clean name (remove schema, quotes)
            obj_name_clean = obj_name.replace('public.', '').replace('"', '')
            
            # Key for deduplication
            key = (obj_type, obj_name_clean)
            
            if obj_type == 'policy':
                # Policy needs table name too: CREATE POLICY "name" ON table
                policy_match = re.search(r'on\s+("?[\w\.]+"?)', text, re.IGNORECASE)
                if policy_match:
                    table_name = policy_match.group(1).lower().replace('public.', '').replace('"', '')
                    key = (obj_type, obj_name_clean, table_name)
            
            if obj_type == 'trigger':
                # Trigger needs table name too: CREATE TRIGGER name ON table
                trigger_match = re.search(r'on\s+("?[\w\.]+"?)', text, re.IGNORECASE)
                if trigger_match:
                    table_name = trigger_match.group(1).lower().replace('public.', '').replace('"', '')
                    key = (obj_type, obj_name_clean, table_name)

            if key not in definition_map:
                definition_map[key] = []
            definition_map[key].append(idx)
            
    # Identify items to keep (The LAST one)
    for key, indices in definition_map.items():
        if len(indices) > 1:
            print(f"Found duplicate: {key} -> {len(indices)} times. Keeping last one.")
            # Mark all but the last for removal
            for i in indices[:-1]:
                to_remove.add(i)
                
    # Also handle "DROP" statements that precede duplicates? 
    # Usually strictly removing earlier definitions is safer IF the last one is the full one.
    # But sometimes earlier one creates table, later one creates table if not exists.
    # If table is created at idx 10 (CREATE TABLE) and idx 500 (CREATE TABLE IF NOT EXISTS), 
    # we should keep idx 10 usually because it might be the rigorous one, OR idx 500 might be the update.
    # Given the file structure (concatenation), the later ones are likely intended as "latest state".
    
    # Special case: TABLES.
    # If we have multiple CREATE TABLE for same table, usually the FIRST one is the main definition 
    # and later ones might be "if not exists" placeholders from merged files.
    # BUT in this file, the merged sections seemed to have full schema copies.
    # Let's check `matches` table. 
    # Line 980: create table if not exists matches ...
    # Line 4097: create table if not exists matches ...
    # They look identical.
    # However, if the first one is "CREATE TABLE" and second is "CREATE TABLE IF NOT EXISTS", removing first one deletes the creation.
    # Wait, if I keep the last one ("IF NOT EXISTS"), and I run the script on a blank DB, it works.
    # So keeping the LAST one is generally safe for "IF NOT EXISTS" too.
    
    # Reconstruct content
    new_content = []
    
    # Header
    new_content.append("-- AUTO-GENERATED CLEAN SCHEMA --\n")
    
    for idx, stmt in enumerate(statements):
        if idx not in to_remove:
            new_content.append(stmt['text'])
        else:
            new_content.append(f"\n-- [REMOVED DUPLICATE] {stmt['text'][:50]}...\n")

    output_path = file_path.replace('.sql', '_clean.sql')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(new_content)
        
    return output_path

if __name__ == "__main__":
    path = r'c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new\supabase_schema.sql'
    out = clean_schema(path)
    print(f"Cleaned schema written to: {out}")
