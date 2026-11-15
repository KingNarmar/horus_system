"""Enable TOTP ONLY in a freshly initialized, unlinked local Supabase stack.

Used by #358 and #370 disposable signed-JWT security workflows. This file
cannot modify hosted Development or Production Auth settings.
"""
import os
from pathlib import Path
import re


def enable_local_totp(config_file=Path("supabase/config.toml")):
    if os.environ.get("SUPABASE_ACCESS_TOKEN") or os.environ.get(
            "SUPABASE_DB_PASSWORD"):
        raise RuntimeError("Hosted Supabase credentials are forbidden")
    if Path("supabase/.temp/project-ref").exists():
        raise RuntimeError("Refusing a linked Supabase project")
    if not config_file.is_file():
        raise RuntimeError("First initialize a disposable local Supabase stack")

    content = config_file.read_text(encoding="utf-8")
    match = re.search(
        r"(?ms)^\[auth\.mfa\.totp\][ \t]*\n(.*?)(?=^\[|\Z)", content
    )
    if match:
        block = match.group(1)
        for name in ("enroll_enabled", "verify_enabled"):
            setting = rf"(?m)^{name}\s*=\s*[^\n]*"
            if re.search(setting, block):
                block = re.sub(setting, lambda _: f"{name} = true", block)
            else:
                block += f"\n{name} = true\n"
        content = content[:match.start(1)] + block + content[match.end(1):]
    else:
        content += (
            "\n[auth.mfa.totp]\n"
            "enroll_enabled = true\n"
            "verify_enabled = true\n"
        )
    config_file.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    enable_local_totp()
