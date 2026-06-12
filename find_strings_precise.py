import os
import re

def find_hardcoded(dir_path):
    results = []
    for root, _, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                for i, line in enumerate(lines):
                    if 'import ' in line or 'l10n.' in line or 'AppIcons' in line or 'AppRoutes' in line: continue
                    if '== \'' in line or '== "' in line or '!= \'' in line or '!= "' in line: continue
                    if 'part ' in line or 'export ' in line: continue
                    # match strings containing letters
                    if re.search(r'[\'"][A-Za-z ]+[\'"]', line):
                        results.append(f'{filepath}:{i+1}: {line.strip()}')
    return results

if __name__ == "__main__":
    for d in [r'C:\My Files\horus_system\lib\features', r'C:\My Files\horus_system\lib\app_shell']:
        if os.path.exists(d):
            res = find_hardcoded(d)
            for r in res: print(r)
