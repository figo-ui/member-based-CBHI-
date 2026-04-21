
import json
import collections

file_path = r'c:\Users\hp\Desktop\Member_Based_CBHI\member_based_cbhi\lib\l10n\app_om.arb'

with open(file_path, 'r', encoding='utf-8') as f:
    # Read line by line to detect duplicates since json.load() only keeps the last one
    keys = []
    for line in f:
        line = line.strip()
        if line.startswith('"') and '":' in line:
            key = line.split('":')[0].strip('"')
            keys.append(key)

duplicates = [item for item, count in collections.Counter(keys).items() if count > 1]
print(f"Found {len(duplicates)} duplicate keys: {duplicates}")
