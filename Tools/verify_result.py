"""Validate a finished playthrough reported by the actual running executable."""
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf8"))
if not (data["passed"] and data["checks"] >= 65 and data["basin"] == 0 and data["endings"] == 3 and data["version"] == "2.0.0"):
    raise SystemExit(f"Parcours incomplet {data}")
print(f"SPOONFUL {data['version']} · {data['checks']} vérifications · {data['backend']}")
