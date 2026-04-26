import re
import sys

def fix_duplicates(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    new_lines = []
    
    in_map = False
    current_keys = set()
    
    for line in lines:
        stripped = line.strip()
        
        # Matches either "'en': {" OR "const _en = <String, String>{"
        if (stripped.startswith("'") and "': {" in stripped) or (stripped.startswith("const") and "<String, String>{" in stripped):
            in_map = True
            current_keys = set()
            new_lines.append(line)
            continue
            
        if in_map and (stripped.startswith("}") or stripped == "};"):
            in_map = False
            new_lines.append(line)
            continue
            
        if in_map:
            # Check if it's a key-value pair
            match = re.match(r"^('[^']+')\s*:", stripped)
            if match:
                key = match.group(1)
                if key in current_keys:
                    print(f"Removing duplicate key {key} in {filepath}")
                    continue # Skip this line
                else:
                    current_keys.add(key)
        
        new_lines.append(line)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))

fix_duplicates(sys.argv[1])
