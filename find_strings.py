import os

def find_hardcoded_strings(dir_path):
    results = []
    for root, _, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    
                for i, line in enumerate(lines):
                    if 'l10n.' in line or 'app_localizations' in filepath:
                        continue
                    if "Text('" in line or 'Text("' in line:
                        results.append(f"{filepath}:{i+1}: {line.strip()}")

    return results

if __name__ == "__main__":
    base_dir = r"C:\My Files\horus_system\lib\features"
    shell_dir = r"C:\My Files\horus_system\lib\app"
    res1 = find_hardcoded_strings(base_dir)
    res2 = find_hardcoded_strings(shell_dir)
    for r in res1 + res2:
        print(r)
