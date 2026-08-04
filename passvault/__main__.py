"""passvault — Encrypted CLI password vault.

Usage:
  python -m passvault init                        Create a new vault
  python -m passvault add                         Add a password (interactive)
  python -m passvault add --service github --user me --pass s3cret --url https://github.com
  python -m passvault get github                  Retrieve by service name
  python -m passvault list                        List all services
  python -m passvault search foo                  Search entries
  python -m passvault generate                    Generate a 24-char password
  python -m passvault delete github               Delete an entry
  python -m passvault export                      Export as JSON (decrypted)
"""
import argparse
import base64
import json
import os
import sqlite3
import string
import secrets
import sys
import getpass
from datetime import datetime, timezone
from pathlib import Path

try:
    from cryptography.fernet import Fernet
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    HAS_CRYPTO = True
except ImportError:
    HAS_CRYPTO = False

DEFAULT_DB = Path.home() / ".passvault" / "vault.db"
KEY_FILE = Path.home() / ".passvault" / "vault.key.salt"

SCHEMA = """
CREATE TABLE IF NOT EXISTS entries (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    service     TEXT NOT NULL UNIQUE,
    username    TEXT DEFAULT '',
    password    TEXT NOT NULL,
    url         TEXT DEFAULT '',
    notes       TEXT DEFAULT '',
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);
"""


# ---------------------------------------------------------------------------
# Key derivation
# ---------------------------------------------------------------------------

def _derive_key(master_password: str, salt: bytes | None = None) -> tuple[bytes, bytes]:
    """Derive a Fernet-compatible 32-byte key from *master_password*.
    Returns (key, salt) — salt is generated if not provided."""
    if salt is None:
        salt = os.urandom(16)
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=600_000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(master_password.encode("utf-8")))
    return key, salt


def _load_key(master_password: str) -> bytes:
    """Load existing salt or create one, then derive and return Fernet key."""
    KEY_FILE.parent.mkdir(parents=True, exist_ok=True)
    if KEY_FILE.exists():
        salt = KEY_FILE.read_bytes()
    else:
        salt = os.urandom(16)
        KEY_FILE.write_bytes(salt)
    key, _ = _derive_key(master_password, salt)
    return key


# ---------------------------------------------------------------------------
# Vault operations
# ---------------------------------------------------------------------------

class Vault:
    def __init__(self, db_path: str | Path | None = None):
        self.db_path = Path(db_path or DEFAULT_DB)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn: sqlite3.Connection | None = None
        self._cipher: Fernet | None = None

    @property
    def conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self.db_path))
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute(SCHEMA)
        return self._conn

    def unlock(self, master_password: str):
        """Derive encryption key from master password. Raises ValueError on mismatch."""
        try:
            key = _load_key(master_password)
            # Verify by decrypting a test value if the vault has entries
            self._cipher = Fernet(key)
            # Quick integrity check: try to decrypt first entry password
            cur = self.conn.execute("SELECT password FROM entries LIMIT 1")
            row = cur.fetchone()
            if row:
                self._cipher.decrypt(row["password"].encode("utf-8"))
        except Exception as exc:
            self._cipher = None
            raise ValueError("Invalid master password or corrupted vault") from exc

    @property
    def cipher(self) -> Fernet:
        if self._cipher is None:
            raise RuntimeError("Vault is locked. Call vault.unlock(password) first.")
        return self._cipher

    def _encrypt(self, plain: str) -> str:
        return self.cipher.encrypt(plain.encode("utf-8")).decode("utf-8")

    def _decrypt(self, token: str) -> str:
        return self.cipher.decrypt(token.encode("utf-8")).decode("utf-8")

    def add(self, service: str, username: str, password: str, url: str = "", notes: str = ""):
        now = datetime.now(timezone.utc).isoformat()
        enc_pw = self._encrypt(password)
        self.conn.execute(
            """INSERT INTO entries (service, username, password, url, notes, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?)
               ON CONFLICT(service) DO UPDATE SET
                   username=excluded.username,
                   password=excluded.password,
                   url=excluded.url,
                   notes=excluded.notes,
                   updated_at=excluded.updated_at""",
            (service.lower(), username, enc_pw, url, notes, now, now),
        )
        self.conn.commit()

    def get(self, service: str) -> dict | None:
        cur = self.conn.execute("SELECT * FROM entries WHERE service = ?", (service.lower(),))
        row = cur.fetchone()
        if row is None:
            return None
        return {
            "id": row["id"],
            "service": row["service"],
            "username": row["username"],
            "password": self._decrypt(row["password"]),
            "url": row["url"],
            "notes": row["notes"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }

    def list_all(self) -> list[dict]:
        cur = self.conn.execute("SELECT id, service, username, url, updated_at FROM entries ORDER BY service")
        return [dict(r) for r in cur.fetchall()]

    def search(self, term: str) -> list[dict]:
        like = f"%{term}%"
        cur = self.conn.execute(
            "SELECT id, service, username, url, updated_at FROM entries WHERE service LIKE ? OR username LIKE ? OR url LIKE ? OR notes LIKE ? ORDER BY service",
            (like, like, like, like),
        )
        return [dict(r) for r in cur.fetchall()]

    def delete(self, service: str) -> bool:
        cur = self.conn.execute("DELETE FROM entries WHERE service = ?", (service.lower(),))
        self.conn.commit()
        return cur.rowcount > 0

    def export_all(self) -> list[dict]:
        cur = self.conn.execute("SELECT * FROM entries ORDER BY service")
        rows = []
        for r in cur.fetchall():
            rows.append({
                "service": r["service"],
                "username": r["username"],
                "password": self._decrypt(r["password"]),
                "url": r["url"],
                "notes": r["notes"],
                "created_at": r["created_at"],
                "updated_at": r["updated_at"],
            })
        return rows


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _unlock_vault(args) -> Vault:
    vault = Vault()
    if not vault.db_path.exists():
        print("No vault found. Run 'python -m passvault init' first.")
        sys.exit(1)
    password = args.master_password or getpass.getpass("Master password: ")
    try:
        vault.unlock(password)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    return vault


def cmd_init(args):
    vault = Vault()
    if vault.db_path.exists():
        print(f"Vault already exists at {vault.db_path}")
        sys.exit(1)
    pw = args.master_password
    if not pw:
        pw = getpass.getpass("Set master password: ")
        confirm = getpass.getpass("Confirm master password: ")
        if pw != confirm:
            print("Passwords do not match.")
            sys.exit(1)
    if not pw:
        print("Password cannot be empty.")
        sys.exit(1)
    vault.db_path.parent.mkdir(parents=True, exist_ok=True)
    vault.conn  # trigger schema creation
    key = _load_key(pw)
    # store a dummy encrypted value to validate the key on future opens
    dummy = Fernet(key).encrypt(b"ok")
    vault.conn.execute("INSERT INTO entries (service, password, created_at, updated_at) VALUES (?, ?, ?, ?)",
                       ("__vault__", dummy.decode(), datetime.now(timezone.utc).isoformat(), datetime.now(timezone.utc).isoformat()))
    vault.conn.commit()
    print(f"Vault initialised at {vault.db_path}")
    print("Store your master password securely — it cannot be recovered.")


def cmd_add(args):
    vault = _unlock_vault(args)
    service = args.service or input("Service: ").strip()
    username = args.username or input("Username: ").strip()
    if args.password:
        password = args.password
    else:
        password = getpass.getpass("Password: ")
    url = args.url or input("URL (optional): ").strip()
    notes = ""
    vault.add(service, username, password, url, notes)
    print(f"Added/updated '{service}'.")


def cmd_get(args):
    vault = _unlock_vault(args)
    entry = vault.get(args.service)
    if entry is None:
        print(f"No entry found for '{args.service}'.")
        sys.exit(1)
    print(f"Service:   {entry['service']}")
    print(f"Username:  {entry['username']}")
    print(f"Password:  {entry['password']}")
    if entry["url"]:
        print(f"URL:       {entry['url']}")
    if entry["notes"]:
        print(f"Notes:     {entry['notes']}")
    print(f"Created:   {entry['created_at']}")
    print(f"Updated:   {entry['updated_at']}")


def cmd_list(args):
    vault = _unlock_vault(args)
    entries = vault.list_all()
    if not entries:
        print("Vault is empty.")
        return
    print(f"{'ID':<4} {'Service':<24} {'Username':<24} {'URL':<40} Updated")
    print("-" * 120)
    for e in entries:
        if e["service"] == "__vault__":
            continue
        print(f"{e['id']:<4} {e['service']:<24} {e['username']:<24} {e['url']:<40} {e['updated_at']}")


def cmd_search(args):
    vault = _unlock_vault(args)
    entries = vault.search(args.term)
    if not entries:
        print("No matches.")
        return
    print(f"{'ID':<4} {'Service':<24} {'Username':<24} {'URL':<40} Updated")
    print("-" * 120)
    for e in entries:
        print(f"{e['id']:<4} {e['service']:<24} {e['username']:<24} {e['url']:<40} {e['updated_at']}")


def cmd_generate(args):
    """Generate a cryptographically random password and print it."""
    length = args.length
    chars = string.ascii_letters + string.digits + "!@#$%^&*()-_=+[]{}|;:,.<>?"
    pw = "".join(secrets.choice(chars) for _ in range(length))
    print(pw)


def cmd_delete(args):
    vault = _unlock_vault(args)
    if vault.delete(args.service):
        print(f"Deleted '{args.service}'.")
    else:
        print(f"No entry found for '{args.service}'.")


def cmd_export(args):
    vault = _unlock_vault(args)
    data = vault.export_all()
    print(json.dumps(data, indent=2))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    if not HAS_CRYPTO:
        print("Error: 'cryptography' package is required.", file=sys.stderr)
        print("Install it with: pip install cryptography", file=sys.stderr)
        sys.exit(1)

    parser = argparse.ArgumentParser(prog="passvault", description="Encrypted CLI password vault")
    parser.add_argument("--master-password", "-m", help="Master password (omit for prompt)")

    sub = parser.add_subparsers(title="commands", required=True)

    p_init = sub.add_parser("init", help="Create a new vault")
    p_init.set_defaults(func=cmd_init)

    p_add = sub.add_parser("add", help="Add or update an entry")
    p_add.add_argument("--service", "-s", help="Service name")
    p_add.add_argument("--username", "-u", help="Username")
    p_add.add_argument("--password", "-p", help="Password (omit for prompt)")
    p_add.add_argument("--url", "-U", help="URL")
    p_add.add_argument("--notes", "-n", help="Notes")
    p_add.set_defaults(func=cmd_add)

    p_get = sub.add_parser("get", help="Retrieve an entry")
    p_get.add_argument("service", help="Service name")
    p_get.set_defaults(func=cmd_get)

    p_list = sub.add_parser("list", help="List all services")
    p_list.set_defaults(func=cmd_list)

    p_search = sub.add_parser("search", help="Search entries")
    p_search.add_argument("term", help="Search term")
    p_search.set_defaults(func=cmd_search)

    p_gen = sub.add_parser("generate", help="Generate a random password")
    p_gen.add_argument("--length", type=int, default=24, help="Password length (default: 24)")
    p_gen.set_defaults(func=cmd_generate)

    p_del = sub.add_parser("delete", help="Delete an entry")
    p_del.add_argument("service", help="Service name")
    p_del.set_defaults(func=cmd_delete)

    p_exp = sub.add_parser("export", help="Export all entries as JSON (decrypted)")
    p_exp.set_defaults(func=cmd_export)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
