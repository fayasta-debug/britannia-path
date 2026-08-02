from pathlib import Path
import re

html = Path(__file__).resolve().parents[1].joinpath("index.html").read_text(encoding="utf-8")
checks = {
    "index tiene contenido": len(html) > 150_000,
    "37 ciclos declarados": html.count('"code":"') == 37,
    "Supabase cargado": "@supabase/supabase-js@2" in html,
    "modal de cuenta": 'id="authModal"' in html,
    "config externa": './config.js' in html,
    "Legal English": "Tax Legal English" in html and "LEGAL_UNITS" in html,
}
for name, ok in checks.items():
    print(("✓" if ok else "✗"), name)
if not all(checks.values()):
    raise SystemExit(1)
