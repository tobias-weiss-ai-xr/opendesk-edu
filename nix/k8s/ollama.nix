{ lib }:
let name = "ollama"; image = "ghcr.io/opendesk-edu/mirror/ollama/ollama"; tag = "0.31.2";
in lib.deployment { inherit name image tag; port = 11434; resources.limits = { cpu = "4"; memory = "16Gi"; }; }
// lib.service { inherit name; port = 11434; }
