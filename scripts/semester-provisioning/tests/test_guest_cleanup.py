"""Tests for guest lecturer cleanup."""

import pytest
from unittest import mock
from datetime import datetime, timedelta
from sync.guest_cleanup import process_guest_cleanup


def test_guest_cleanup_expired_disables(monkeypatch):
    """Expired guest accounts should be disabled and groups removed."""
    
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")
    
    with mock.patch("sync.guest_cleanup.KeycloakClient") as MockKC:
        kc_instance = mock.MagicMock()
        MockKC.return_value = kc_instance
        
        expired_date = (datetime.utcnow() - timedelta(days=5)).isoformat()
        kc_instance._request.return_value.json.return_value = [
            {
                "id": "g1",
                "username": "expired_guest",
                "attributes": {
                    "guestLecturer": ["true"],
                    "accountExpiry": [expired_date],
                },
            },
        ]
        kc_instance.list_user_groups.return_value = [
            {"id": "g1", "name": "group-a"},
            {"id": "g2", "name": "group-b"},
        ]
        
        result = process_guest_cleanup(dry_run=False)
        
        assert result["expired_and_disabled"] == 1
        kc_instance.disable_user.assert_called_once_with("g1")
        assert kc_instance.remove_group.call_count == 2


def test_guest_cleanup_active_skipped(monkeypatch):
    """Active (non-expired) guest accounts should be left untouched."""
    
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")
    
    with mock.patch("sync.guest_cleanup.KeycloakClient") as MockKC:
        kc_instance = mock.MagicMock()
        MockKC.return_value = kc_instance
        
        future_date = (datetime.utcnow() + timedelta(days=100)).isoformat()
        kc_instance._request.return_value.json.return_value = [
            {
                "id": "g2",
                "username": "active_guest",
                "attributes": {
                    "guestLecturer": ["true"],
                    "accountExpiry": [future_date],
                },
            },
        ]
        
        result = process_guest_cleanup(dry_run=False)
        assert result["expired_and_disabled"] == 0
        kc_instance.disable_user.assert_not_called()


def test_guest_cleanup_no_expiry_skipped(monkeypatch):
    """Guest without expiry should be skipped."""
    
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")
    
    with mock.patch("sync.guest_cleanup.KeycloakClient") as MockKC:
        kc_instance = mock.MagicMock()
        MockKC.return_value = kc_instance
        
        kc_instance._request.return_value.json.return_value = [
            {
                "id": "g3",
                "username": "no_expiry_guest",
                "attributes": {
                    "guestLecturer": ["true"],
                },
            },
        ]
        
        result = process_guest_cleanup(dry_run=False)
        assert result["expired_and_disabled"] == 0
        kc_instance.disable_user.assert_not_called()


def test_guest_cleanup_dry_run(monkeypatch):
    """Dry run should not modify accounts."""
    
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")
    
    with mock.patch("sync.guest_cleanup.KeycloakClient") as MockKC:
        kc_instance = mock.MagicMock()
        MockKC.return_value = kc_instance
        
        expired_date = (datetime.utcnow() - timedelta(days=5)).isoformat()
        kc_instance._request.return_value.json.return_value = [
            {
                "id": "g4",
                "username": "dry_run_guest",
                "attributes": {
                    "guestLecturer": ["true"],
                    "accountExpiry": [expired_date],
                },
            },
        ]
        
        result = process_guest_cleanup(dry_run=True)
        
        assert result["expired_and_disabled"] == 1
        kc_instance.disable_user.assert_not_called()
        kc_instance.remove_group.assert_not_called()


def test_guest_cleanup_expiring_soon_warned(monkeypatch):
    """Accounts expiring within 14 days should be logged as warnings."""
    
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")
    
    with mock.patch("sync.guest_cleanup.KeycloakClient") as MockKC:
        kc_instance = mock.MagicMock()
        MockKC.return_value = kc_instance
        
        near_expiry = (datetime.utcnow() + timedelta(days=7)).isoformat()
        kc_instance._request.return_value.json.return_value = [
            {
                "id": "g5",
                "username": "expiring_soon_guest",
                "attributes": {
                    "guestLecturer": ["true"],
                    "accountExpiry": [near_expiry],
                },
            },
        ]
        
        result = process_guest_cleanup(dry_run=False)
        
        assert result["expired_and_disabled"] == 0
        assert result["expiring_soon_warned"] == 1
        assert len(result["expiring_soon"]) == 1
        kc_instance.disable_user.assert_not_called()
