#!/usr/bin/env python3
"""
Convert Helmfile chart values to Nix module.
Usage: python3 scripts/helmfile2nix.py helmfile/charts/mariadb/values.yaml > nix/k8s/mariadb.nix
"""
import sys, yaml, json

def guess_type(name, val):
    if name == 'port' or name.endswith('Port'):
        return val
    if name == 'replicas':
        return val
    if name == 'image':
        return val.replace('ghcr.io/', 'ghcr.io/opendesk-edu/')
    return None

def convert(values_file):
    with open(values_file) as f:
        vals = yaml.safe_load(f)
    
    # Extract basic info
    name = vals.get('name', 'service')
    image = vals.get('image', {})
    repo = image.get('repository', 'nginx')
    tag = image.get('tag', 'latest')
    port = vals.get('port', 80)
    
    # Generate Nix
    print('{ lib }:')
    print()
    print('let')
    print(f'  name = "{name}";')
    print(f'  image = "{repo}";')
    print(f'  tag = "{tag}";')
    print('in')
    print()
    print('lib.deployment {')
    print(f'  inherit name image tag;')
    print(f'  port = {port};')
    
    if 'resources' in vals:
        res = vals['resources']
        limits = res.get('limits', {})
        requests = res.get('requests', {})
        if limits:
            print(f'  resources.limits = {{ cpu = "{limits.get("cpu","500m")}"; memory = "{limits.get("memory","512Mi")}"; }};')
    
    print('}')
    print('// lib.service { inherit name; port = port; }')

if __name__ == '__main__':
    convert(sys.argv[1])
