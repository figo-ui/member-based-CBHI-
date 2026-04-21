
import json
import os

base_path = r'c:\Users\hp\Desktop\Member_Based_CBHI\member_based_cbhi\lib\l10n'
en_path = os.path.join(base_path, 'app_en.arb')
om_path = os.path.join(base_path, 'app_om.arb')

def clean_arb(path):
    with open(path, 'r', encoding='utf-8') as f:
        # We need to handle potential duplicates at the source level
        lines = f.readlines()
        
    # Simple manual parse to keep the last occurrence of each key
    data = {}
    for line in lines:
        line = line.strip()
        if line.startswith('"') and '":' in line:
            parts = line.split('":', 1)
            key = parts[0].strip().strip('"')
            value = parts[1].strip().rstrip(',').strip().strip('"')
            data[key] = value

    return data

en_data = clean_arb(en_path)
om_data = clean_arb(om_path)

# Ensure om has all keys from en, or at least keep what it has.
# Also remove keys that started with @@ or @ if we don't have them in OM (except @@locale)
new_om = {"@@locale": "om"}
for key in en_data:
    if key.startswith("@@") or key.startswith("@"):
        # Copy metadata if it exists in EN
        # (Though OM might not have all @ metadata)
        continue
    
    if key in om_data:
        new_om[key] = om_data[key]
    else:
        # If missing in OM, we might want to flag it or use EN as fallback (though Flutter does this anyway)
        # For now, let's just keep what's in OM and deduplicate.
        pass

# Also keep keys that are in OM but not in EN (if any, though usually EN is the template)
for key in om_data:
    if key not in new_om and not key.startswith("@"):
        new_om[key] = om_data[key]

# Write back cleaned OM
with open(om_path, 'w', encoding='utf-8') as f:
    json.dump(new_om, f, indent=2, ensure_ascii=False)

print(f"Cleaned {om_path}. Total keys: {len(new_om)}")
