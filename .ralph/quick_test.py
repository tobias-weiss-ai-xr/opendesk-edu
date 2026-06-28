#!/usr/bin/env python3
"""Quick test of the Ralph loop with limited tasks."""
import subprocess
import datetime
from pathlib import Path

REPORT_DIR = Path('.ralph/reports')
REPORT_DIR.mkdir(parents=True, exist_ok=True)

results = []
start = datetime.datetime.now()

print("=" * 70)
print("Ralph Loop Quick Test - Iteration 1")
print(f"Started: {start.isoformat()}")
print("=" * 70)

# Test 1: HTTPS availability
print("\n[Test 1] Checking HTTPS availability of all subdomains...")
test = subprocess.run(
    'for d in chemie-lernen.org opendesk-edu.org landscape.opendesk-edu.org openspec.opendesk-edu.org; do status=$(curl -sk -o /dev/null -w "%{http_code}" "https://$d/"); echo "$d: $status"; done',
    shell=True, capture_output=True, text=True, timeout=30
)
print(test.stdout)
results.append({"name": "check-https", "success": test.returncode == 0, "output": test.stdout})

# Test 2: Loki
print("\n[Test 2] Checking Loki status...")
test = subprocess.run('curl -s --max-time 5 http://178.254.2.90:3100/ready 2>&1', shell=True, capture_output=True, text=True, timeout=10)
print(f"Loki: {test.stdout or 'not reachable'}")
results.append({"name": "check-loki", "success": "ready" in test.stdout, "output": test.stdout})

# Test 3: Disk space
print("\n[Test 3] Checking disk space...")
test = subprocess.run('df -h / | tail -1', shell=True, capture_output=True, text=True, timeout=5)
print(test.stdout)
results.append({"name": "check-disk", "success": test.returncode == 0, "output": test.stdout})

# Test 4: Recent articles
print("\n[Test 4] Counting recent articles...")
test = subprocess.run('find articles/ -name "*.md" -mtime -30 2>/dev/null | wc -l', shell=True, capture_output=True, text=True, timeout=5)
print(f"Recent articles (30 days): {test.stdout.strip()}")
results.append({"name": "check-articles", "success": int(test.stdout.strip() or 0) >= 3, "output": test.stdout})

# Summary
end = datetime.datetime.now()
duration = (end - start).total_seconds()
passed = sum(1 for r in results if r["success"])

print("\n" + "=" * 70)
print(f"SUMMARY: {passed}/{len(results)} tests passed in {duration:.2f}s")
print("=" * 70)

# Save report
report = f"""# Ralph Loop Quick Test Report

**Date**: {start.isoformat()}
**Duration**: {duration:.2f}s
**Passed**: {passed}/{len(results)}

## Results

"""
for r in results:
    status = "[OK]" if r["success"] else "[FAIL]"
    report += f"### {status} {r['name']}\n```\n{r['output']}\n```\n\n"

report_file = REPORT_DIR / f"quick-test-{start.strftime('%Y%m%d-%H%M%S')}.md"
report_file.write_text(report)
print(f"\nReport saved: {report_file}")
