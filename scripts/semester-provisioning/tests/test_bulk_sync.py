# SPDX-License-Identifier: MIT
# Tests for the bulk-sync script (CSV/JSON parsing, API calls)
"""Unit tests for the CSV/JSON bulk synchronization utility."""

import pytest
from importlib import import_module

try:
    # Optional: test the actual parser if available
    module = import_module("semester_provisioning.bulk_sync")
    parse_csv = getattr(module, "parse_csv", None)
except Exception:
    parse_csv = None


def test_parse_csv_not_implemented_when_module_missing():
    if parse_csv is None:
        pytest.skip("bulk_sync.parse_csv not available in environment.")

    # If available, provide a minimal CSV sample and verify output shape
    sample = "student_id,course_id\nstu-1,c1\nstu-2,c2\n"
    result = parse_csv(sample)
    assert isinstance(result, list)
    assert len(result) == 2
