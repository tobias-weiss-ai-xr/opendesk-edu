{ lib }:
let name = "ollama"; image = "ghcr.io/opendesk-edu/ollama"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 11434; }) (lib.service { inherit name; port = 11434; }) ]
