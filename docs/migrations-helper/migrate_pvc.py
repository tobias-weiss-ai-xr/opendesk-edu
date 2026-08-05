#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2025-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

import configargparse
import json
import logging
import os
import subprocess
import sys
import tempfile
import time
from typing import Dict, List, Optional, Tuple

import yaml
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from kubernetes.utils.quantity import parse_quantity
from configargparse import ArgumentTypeError

class PVCMigrator:
    def __init__(self,
        namespace: str,
        old_pvc_name: str,
        new_storageclass: str,
        new_size: str,
        migrator_image: str,
        pause_after_copy: bool,
        yes_i_know_the_risk: bool,
        logger
    ):

        self.namespace = namespace
        self.old_pvc_name = old_pvc_name
        self.new_storageclass = new_storageclass
        self.new_size = new_size
        self.migrator_image = migrator_image
        self.pause_after_copy = pause_after_copy
        self.yes_i_know_the_risk = yes_i_know_the_risk
        self.logger = logger
        self.migrator_pod = "pvc-migrator"
        self.tmp_pvc_name = f"{old_pvc_name}-new"
        self.new_pvc_name = None
        self.scale_info_file = None

        # Initialize Kubernetes clients
        try:
            config.load_incluster_config()
        except config.ConfigException:
            config.load_kube_config()

        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
        self.storage_v1 = client.StorageV1Api()

    def wait_for_pvc_bound(self, pvc_name: str, timeout: int = 300) -> bool:
        """Wait for PVC to be bound."""
        self.logger.info(f"Waiting for PVC '{pvc_name}' to be bound...")
        elapsed = 0

        while elapsed < timeout:
            try:
                pvc = self.v1.read_namespaced_persistent_volume_claim(
                    name=pvc_name, namespace=self.namespace
                )
                phase = pvc.status.phase if pvc.status else "Unknown"
                volume_name = pvc.spec.volume_name if pvc.spec else ""

                if phase == "Bound" and volume_name:
                    self.logger.info(f"PVC '{pvc_name}' is bound to volume '{volume_name}'")
                    return True

                self.logger.info(f"PVC phase: {phase}, waiting... ({elapsed}s/{timeout}s)")
                time.sleep(5)
                elapsed += 5

            except ApiException as e:
                self.logger.error(f"Error checking PVC status: {e}")
                time.sleep(5)
                elapsed += 5

        self.logger.error(f"PVC '{pvc_name}' did not bind within {timeout}s")
        return False

    def get_storage_class_binding_mode(self) -> str:
        """Get the binding mode of the storage class."""
        try:
            self.logger.debug(f"--> {self.new_storageclass}")
            sc = self.storage_v1.read_storage_class(name=self.new_storageclass)
            return sc.volume_binding_mode or "Immediate"
        except ApiException as e:
            self.logger.error(f"Error reading storage class: {e}")
            return "Immediate"

    def get_workloads_using_pvc(self) -> Dict[str, List[Tuple[str, int]]]:
        """Get all workloads using the PVC and their replica counts."""
        workloads = {
            'deployments': [],
            'statefulsets': [],
            'replicasets': [],
            'pods': []
        }

        self.logger.info(f"=== Looking for workloads using PVC '{self.old_pvc_name}' ===")

        # Check Deployments
        try:
            deployments = self.apps_v1.list_namespaced_deployment(namespace=self.namespace)
            self.logger.debug(f"Found {len(deployments.items)} deployments in namespace '{self.namespace}'")
            for deploy in deployments.items:
                self.logger.debug(f"Checking Deployment '{deploy.metadata.name}'")
                if self._uses_pvc(deploy.spec.template.spec.volumes):
                    replicas = deploy.spec.replicas or 1
                    workloads['deployments'].append((deploy.metadata.name, replicas))
                    self.logger.debug(f"✓ Deployment '{deploy.metadata.name}' uses PVC '{self.old_pvc_name}' (replicas: {replicas})")
        except ApiException as e:
            self.logger.warning(f"Error listing deployments: {e}")

        # Check StatefulSets with enhanced debugging
        try:
            statefulsets = self.apps_v1.list_namespaced_stateful_set(namespace=self.namespace)
            self.logger.debug(f"Found {len(statefulsets.items)} statefulsets in namespace '{self.namespace}'")

            for sts in statefulsets.items:
                sts_name = sts.metadata.name
                self.logger.debug(f"Checking StatefulSet '{sts_name}'")

                # Debug volumes
                volumes = sts.spec.template.spec.volumes if sts.spec.template.spec.volumes else []
                self.logger.debug(f"StatefulSet '{sts_name}' has {len(volumes)} volumes")
                for i, volume in enumerate(volumes):
                    if volume.persistent_volume_claim:
                        pvc_name = volume.persistent_volume_claim.claim_name
                        self.logger.debug(f"StatefulSet '{sts_name}' volume[{i}] uses PVC '{pvc_name}'")
                    else:
                        self.logger.debug(f"StatefulSet '{sts_name}' volume[{i}] name='{volume.name}' (not a PVC volume)")

                # Debug volumeClaimTemplates (StatefulSet-specific)
                volume_claim_templates = sts.spec.volume_claim_templates if sts.spec.volume_claim_templates else []
                self.logger.debug(f"StatefulSet '{sts_name}' has {len(volume_claim_templates)} volumeClaimTemplates")
                for i, vct in enumerate(volume_claim_templates):
                    vct_name = vct.metadata.name
                    self.logger.debug(f"StatefulSet '{sts_name}' volumeClaimTemplate[{i}] name='{vct_name}'")
                    # For volumeClaimTemplates, the actual PVC name is: {template-name}-{sts-name}-{ordinal}
                    expected_pvc_pattern = f"{vct_name}-{sts_name}-"
                    if self.old_pvc_name.startswith(expected_pvc_pattern):
                        self.logger.debug(f"✓ StatefulSet volumeClaimTemplate matches PVC pattern: '{expected_pvc_pattern}*'")

                # Check regular volumes
                uses_pvc_volumes = self._uses_pvc(volumes)

                # Check volumeClaimTemplates
                uses_pvc_templates = self._uses_pvc_in_volume_claim_templates(sts_name, volume_claim_templates)

                if uses_pvc_volumes or uses_pvc_templates:
                    replicas = sts.spec.replicas or 1
                    workloads['statefulsets'].append((sts_name, replicas))
                    reason = "volumes" if uses_pvc_volumes else "volumeClaimTemplates"
                    self.logger.debug(f"✓ StatefulSet '{sts_name}' uses PVC '{self.old_pvc_name}' via {reason} (replicas: {replicas})")
                else:
                    self.logger.debug(f"✗ StatefulSet '{sts_name}' does not use PVC '{self.old_pvc_name}'")

        except ApiException as e:
            self.logger.warning(f"Error listing statefulsets: {e}")

        # Check ReplicaSets (not managed by Deployments)
        try:
            replicasets = self.apps_v1.list_namespaced_replica_set(namespace=self.namespace)
            self.logger.debug(f"Found {len(replicasets.items)} replicasets in namespace '{self.namespace}'")
            for rs in replicasets.items:
                # Skip if managed by a deployment
                if rs.metadata.owner_references:
                    self.logger.debug(f"Skipping ReplicaSet '{rs.metadata.name}' (managed by another resource)")
                    continue
                self.logger.debug(f"Checking ReplicaSet '{rs.metadata.name}'")
                if self._uses_pvc(rs.spec.template.spec.volumes):
                    replicas = rs.spec.replicas or 1
                    workloads['replicasets'].append((rs.metadata.name, replicas))
                    self.logger.debug(f"✓ ReplicaSet '{rs.metadata.name}' uses PVC '{self.old_pvc_name}' (replicas: {replicas})")
        except ApiException as e:
            self.logger.warning(f"Error listing replicasets: {e}")

        # Check standalone Pods
        try:
            pods = self.v1.list_namespaced_pod(namespace=self.namespace)
            self.logger.debug(f"Found {len(pods.items)} pods in namespace '{self.namespace}'")
            for pod in pods.items:
                # Skip if managed by another resource
                if pod.metadata.owner_references:
                    continue
                self.logger.debug(f"Checking standalone Pod '{pod.metadata.name}'")
                if self._uses_pvc(pod.spec.volumes):
                    workloads['pods'].append((pod.metadata.name, 1))
                    self.logger.debug(f"✓ Pod '{pod.metadata.name}' uses PVC '{self.old_pvc_name}'")
        except ApiException as e:
            self.logger.warning(f"Error listing pods: {e}")

        # Summary
        total_workloads = sum(len(wl) for wl in workloads.values())
        self.logger.debug(f"Total workloads found using PVC '{self.old_pvc_name}': {total_workloads}")
        for wl_type, wl_list in workloads.items():
            if wl_list:
                self.logger.debug(f"{wl_type}: {[name for name, _ in wl_list]}")

        return workloads

    def _uses_pvc(self, volumes) -> bool:
        """Check if volumes list uses the target PVC."""
        if not volumes:
            return False
        for volume in volumes:
            if (volume.persistent_volume_claim and
                volume.persistent_volume_claim.claim_name == self.old_pvc_name):
                return True
        return False

    def _uses_pvc_in_volume_claim_templates(self, sts_name: str, volume_claim_templates) -> bool:
        """Check if StatefulSet volumeClaimTemplates generate the target PVC."""
        if not volume_claim_templates:
            return False

        for vct in volume_claim_templates:
            template_name = vct.metadata.name
            # StatefulSet volumeClaimTemplates create PVCs with pattern: {template-name}-{sts-name}-{ordinal}
            expected_pvc_pattern = f"{template_name}-{sts_name}-"
            if self.old_pvc_name.startswith(expected_pvc_pattern):
                # Extract ordinal to validate it's a number
                try:
                    ordinal_part = self.old_pvc_name[len(expected_pvc_pattern):]
                    int(ordinal_part)  # This will raise ValueError if not a number
                    self.logger.debug(f"PVC '{self.old_pvc_name}' matches StatefulSet volumeClaimTemplate pattern '{expected_pvc_pattern}{ordinal_part}'")
                    return True
                except ValueError:
                    # Not a valid ordinal, continue checking
                    continue

        return False

    def scale_down_workloads(self):
        """Scale down all workloads using the PVC."""
        self.logger.info(f"=== Step 0: Detecting and scaling down workloads using PVC '{self.old_pvc_name}' ===")

        workloads = self.get_workloads_using_pvc()
        scale_info = []

        # Scale down Deployments
        for name, replicas in workloads['deployments']:
            self.logger.info(f"Scaling down Deployment/{name} from {replicas} to 0...")
            try:
                self.apps_v1.patch_namespaced_deployment_scale(
                    name=name,
                    namespace=self.namespace,
                    body={'spec': {'replicas': 0}}
                )
                scale_info.append(f"Deployment/{name} {replicas}")
            except ApiException as e:
                self.logger.error(f"Error scaling deployment {name}: {e}")

        # Scale down StatefulSets
        for name, replicas in workloads['statefulsets']:
            self.logger.info(f"Scaling down StatefulSet/{name} from {replicas} to 0...")
            try:
                self.apps_v1.patch_namespaced_stateful_set_scale(
                    name=name,
                    namespace=self.namespace,
                    body={'spec': {'replicas': 0}}
                )
                scale_info.append(f"StatefulSet/{name} {replicas}")
            except ApiException as e:
                self.logger.error(f"Error scaling statefulset {name}: {e}")

        # Scale down ReplicaSets
        for name, replicas in workloads['replicasets']:
            self.logger.info(f"Scaling down ReplicaSet/{name} from {replicas} to 0...")
            try:
                self.apps_v1.patch_namespaced_replica_set_scale(
                    name=name,
                    namespace=self.namespace,
                    body={'spec': {'replicas': 0}}
                )
                scale_info.append(f"ReplicaSet/{name} {replicas}")
            except ApiException as e:
                self.logger.error(f"Error scaling replicaset {name}: {e}")

        # Delete standalone Pods
        for name, _ in workloads['pods']:
            self.logger.info(f"Deleting standalone Pod/{name}...")
            try:
                self.v1.delete_namespaced_pod(
                    name=name,
                    namespace=self.namespace,
                    grace_period_seconds=0
                )
                scale_info.append(f"Pod/{name} 1")
            except ApiException as e:
                self.logger.error(f"Error deleting pod {name}: {e}")

        # Handle scale info
        if not scale_info:
            sys.exit("No scale info found, aborting...")
        else:
            self.scale_info_file = tempfile.NamedTemporaryFile(mode='w', delete=False, prefix='pvc-migration-')
            self.scale_info_file.write('\n'.join(scale_info))
            self.scale_info_file.close()

            self.logger.info("Scale down complete. Workloads scaled down:")
            for info in scale_info:
                self.logger.info(f"  {info}")

        # Wait for pods to terminate
        self.logger.info("Waiting for pods to terminate...")
        time.sleep(10)

    def scale_up_workloads(self):
        """Scale workloads back up to original replica counts."""
        self.logger.info("=== Step 16: Scaling workloads back up to original replica counts ===")

        if not self.scale_info_file or not os.path.exists(self.scale_info_file.name):
            self.logger.info("No scale info found, skipping scale up")
            return

        with open(self.scale_info_file.name, 'r') as f:
            scale_info = f.read().strip().split('\n')

        for line in scale_info:
            if not line:
                continue

            parts = line.split()
            if len(parts) != 2:
                continue

            kind_name, replicas = parts
            kind, name = kind_name.split('/', 1)
            replicas = int(replicas)

            try:
                if kind == "Deployment":
                    self.logger.info(f"Scaling up Deployment/{name} to {replicas} replicas...")
                    self.apps_v1.patch_namespaced_deployment_scale(
                        name=name,
                        namespace=self.namespace,
                        body={'spec': {'replicas': replicas}}
                    )
                elif kind == "StatefulSet":
                    self.logger.info(f"Scaling up StatefulSet/{name} to {replicas} replicas...")
                    self.apps_v1.patch_namespaced_stateful_set_scale(
                        name=name,
                        namespace=self.namespace,
                        body={'spec': {'replicas': replicas}}
                    )
                elif kind == "ReplicaSet":
                    self.logger.info(f"Scaling up ReplicaSet/{name} to {replicas} replicas...")
                    self.apps_v1.patch_namespaced_replica_set_scale(
                        name=name,
                        namespace=self.namespace,
                        body={'spec': {'replicas': replicas}}
                    )
                elif kind == "Pod":
                    self.logger.info(f"Warning: Standalone pods cannot be automatically recreated. Please recreate Pod/{name} manually.")
            except ApiException as e:
                self.logger.error(f"Error scaling up {kind_name}: {e}")

    def get_pvc_info(self) -> Tuple[str, str, str]:
        """Get current PVC information."""
        try:
            pvc = self.v1.read_namespaced_persistent_volume_claim(
                name=self.old_pvc_name, namespace=self.namespace
            )
            old_size = pvc.spec.resources.requests['storage']
            access_mode = pvc.spec.access_modes[0]
            old_sc = pvc.spec.storage_class_name
            return old_size, access_mode, old_sc
        except ApiException as e:
            self.logger.error(f"Error reading PVC: {e}")
            raise

    def create_temporary_pvc(self, access_mode: str):
        """Create temporary PVC with new storage class and size."""
        pvc_manifest = {
            'apiVersion': 'v1',
            'kind': 'PersistentVolumeClaim',
            'metadata': {'name': self.tmp_pvc_name},
            'spec': {
                'accessModes': [access_mode],
                'resources': {'requests': {'storage': self.new_size}},
                'storageClassName': self.new_storageclass
            }
        }

        try:
            self.v1.create_namespaced_persistent_volume_claim(
                namespace=self.namespace,
                body=pvc_manifest
            )
        except ApiException as e:
            self.logger.error(f"Error creating temporary PVC: {e}")
            raise

    def create_migration_pod(self):
        """Create pod for data migration."""
        pod_manifest = {
            'apiVersion': 'v1',
            'kind': 'Pod',
            'metadata': {'name': self.migrator_pod},
            'spec': {
                'containers': [{
                    'name': 'migrator',
                    'image': self.migrator_image,
                    'command': ['sh', '-c', 'sleep infinity'],
                    'volumeMounts': [
                        {'name': 'old', 'mountPath': '/mnt/old'},
                        {'name': 'new', 'mountPath': '/mnt/new'}
                    ]
                }],
                'volumes': [
                    {
                        'name': 'old',
                        'persistentVolumeClaim': {'claimName': self.old_pvc_name}
                    },
                    {
                        'name': 'new',
                        'persistentVolumeClaim': {'claimName': self.tmp_pvc_name}
                    }
                ],
                'restartPolicy': 'Never'
            }
        }

        try:
            self.v1.create_namespaced_pod(
                namespace=self.namespace,
                body=pod_manifest
            )
        except ApiException as e:
            self.logger.error(f"Error creating migration pod: {e}")
            raise

    def wait_for_pod_ready(self, timeout: int = 300) -> bool:
        """Wait for migration pod to be ready."""
        self.logger.info("Waiting for migration pod to be ready...")
        elapsed = 0

        while elapsed < timeout:
            try:
                pod = self.v1.read_namespaced_pod(
                    name=self.migrator_pod, namespace=self.namespace
                )

                if pod.status.conditions:
                    for condition in pod.status.conditions:
                        if condition.type == "Ready" and condition.status == "True":
                            return True

                time.sleep(5)
                elapsed += 5

            except ApiException as e:
                self.logger.error(f"Error checking pod status: {e}")
                time.sleep(5)
                elapsed += 5

        return False

    def copy_data(self):
        """Copy data between PVCs using rsync."""
        self.logger.info("=== Step 6: Copy data inside cluster ===")

        copy_script = """
        apk add --no-cache rsync >/dev/null 2>&1
        echo 'Starting data copy...'
        rsync -av --progress /mnt/old/ /mnt/new/
        echo 'Data copy completed'
        echo 'Verifying copy...'
        OLD_FILES=$(find /mnt/old -type f | wc -l)
        NEW_FILES=$(find /mnt/new -type f | wc -l)
        echo "Files in source: $OLD_FILES"
        echo "Files in destination: $NEW_FILES"
        if [ $OLD_FILES -eq $NEW_FILES ]; then
            echo 'File count verification: PASSED'
        else
            echo 'File count verification: FAILED'
            exit 1
        fi
        """

        try:
            result = subprocess.run([
                'kubectl', 'exec', '-n', self.namespace, self.migrator_pod,
                '--', 'sh', '-c', copy_script
            ], capture_output=True, text=True, check=True)

            self.logger.info(result.stdout)

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Error copying data: {e}")
            self.logger.error(f"Stderr: {e.stderr}")
            raise

    def patch_resource(self, resource_type: str, name: str, patch: dict, is_pv: bool = False):
        """Generic patch function for Kubernetes resources."""
        try:
            if is_pv:
                self.v1.patch_persistent_volume(name=name, body=patch)
            elif resource_type == 'pvc':
                self.v1.patch_namespaced_persistent_volume_claim(
                    name=name, namespace=self.namespace, body=patch
                )
        except ApiException as e:
            self.logger.warning(f"Error patching {resource_type} {name}: {e}")

    def get_pv_name(self) -> str:
        """Get PV name from temporary PVC."""
        try:
            pvc = self.v1.read_namespaced_persistent_volume_claim(
                name=self.tmp_pvc_name, namespace=self.namespace
            )
            return pvc.spec.volume_name
        except ApiException as e:
            self.logger.error(f"Error getting PV name: {e}")
            raise

    def create_final_pvc(self, access_mode: str):
        """Create final PVC with original name."""
        pvc_manifest = {
            'apiVersion': 'v1',
            'kind': 'PersistentVolumeClaim',
            'metadata': {'name': self.old_pvc_name},
            'spec': {
                'accessModes': [access_mode],
                'resources': {'requests': {'storage': self.new_size}},
                'storageClassName': self.new_storageclass,
                'volumeName': self.new_pvc_name
            }
        }

        try:
            self.v1.create_namespaced_persistent_volume_claim(
                namespace=self.namespace,
                body=pvc_manifest
            )
        except ApiException as e:
            self.logger.error(f"Error creating final PVC: {e}")
            raise

    def cleanup(self):
        """Clean up temporary resources."""
        self.logger.info("Cleaning up...")

        # Delete migration pod
        try:
            self.v1.delete_namespaced_pod(
                name=self.migrator_pod,
                namespace=self.namespace,
                grace_period_seconds=0
            )
        except ApiException:
            pass

        # Delete temporary PVC
        try:
            self.v1.delete_namespaced_persistent_volume_claim(
                name=self.tmp_pvc_name,
                namespace=self.namespace
            )
        except ApiException:
            pass

        # Clean up scale info file
        if self.scale_info_file and os.path.exists(self.scale_info_file.name):
            os.unlink(self.scale_info_file.name)

    def debug_specific_statefulset(self, sts_name: str):
        """Debug a specific StatefulSet to understand its PVC usage."""
        self.logger.info(f"=== Detailed analysis of StatefulSet '{sts_name}' ===")

        try:
            sts = self.apps_v1.read_namespaced_stateful_set(name=sts_name, namespace=self.namespace)

            self.logger.info(f"StatefulSet '{sts_name}' details:")
            self.logger.info(f"  Replicas: {sts.spec.replicas}")

            # Check volumes
            volumes = sts.spec.template.spec.volumes if sts.spec.template.spec.volumes else []
            self.logger.info(f"  Regular volumes ({len(volumes)}):")
            for i, volume in enumerate(volumes):
                if volume.persistent_volume_claim:
                    pvc_name = volume.persistent_volume_claim.claim_name
                    self.logger.info(f"    [{i}] {volume.name} -> PVC: {pvc_name}")
                    if pvc_name == self.old_pvc_name:
                        self.logger.info(f"        ✓ MATCHES target PVC!")
                else:
                    self.logger.info(f"    [{i}] {volume.name} -> {volume}")

            # Check volumeClaimTemplates
            vcts = sts.spec.volume_claim_templates if sts.spec.volume_claim_templates else []
            self.logger.info(f"  Volume claim templates ({len(vcts)}):")
            for i, vct in enumerate(vcts):
                template_name = vct.metadata.name
                expected_pattern = f"{template_name}-{sts_name}-"
                self.logger.info(f"    [{i}] {template_name}")
                self.logger.info(f"        Expected PVC pattern: {expected_pattern}*")
                if self.old_pvc_name.startswith(expected_pattern):
                    self.logger.info(f"        ✓ MATCHES target PVC '{self.old_pvc_name}'!")

            # List actual pods to see their PVC usage
            self.logger.info(f"  Pods for StatefulSet '{sts_name}':")
            label_selector = f"app={sts_name}"  # Common pattern, might need adjustment
            try:
                pods = self.v1.list_namespaced_pod(
                    namespace=self.namespace,
                    label_selector=label_selector
                )
                for pod in pods.items:
                    if pod.metadata.owner_references:
                        for owner in pod.metadata.owner_references:
                            if owner.kind == "StatefulSet" and owner.name == sts_name:
                                self.logger.info(f"    Pod: {pod.metadata.name}")
                                pod_volumes = pod.spec.volumes if pod.spec.volumes else []
                                for vol in pod_volumes:
                                    if vol.persistent_volume_claim:
                                        pvc_name = vol.persistent_volume_claim.claim_name
                                        self.logger.info(f"      Volume: {vol.name} -> PVC: {pvc_name}")
                                        if pvc_name == self.old_pvc_name:
                                            self.logger.info(f"        ✓ MATCHES target PVC!")
            except ApiException as e:
                self.logger.warning(f"Could not list pods for StatefulSet: {e}")

        except ApiException as e:
            self.logger.error(f"Error reading StatefulSet '{sts_name}': {e}")

    def migrate(self):
        """Main migration process."""
        try:
            # Add specific debugging if you suspect a particular StatefulSet
            # Uncomment and modify the following line if you want to debug a specific StatefulSet
            # self.debug_specific_statefulset("ox-connector")  # Remove the "-0" suffix

            # Get current PVC info
            self.logger.info("=== Step 1: Get current PVC information ===")
            old_size, access_mode, old_sc = self.get_pvc_info()

            if not self.new_storageclass:
                self.new_storageclass = old_sc
            if not self.new_size:
                self.new_size = old_size

            # Validate size
            old_size_bytes = parse_quantity(old_size)
            old_size_str   = f"{old_size_bytes / (1024**2)} Mi"
            new_size_bytes = parse_quantity(self.new_size)
            new_size_str   = f"{new_size_bytes / (1024**2)} Mi"

            if new_size_bytes < old_size_bytes:
                raise ValueError(f"New size ({new_size_str}) cannot be smaller than current size ({old_size_str})")

            self.logger.info("Current PVC info:")
            self.logger.info(f"  Storage Class: {old_sc}")
            self.logger.info(f"  Size: {old_size_str}")
            self.logger.info(f"  Access Mode: {access_mode}")
            self.logger.info("")
            self.logger.info("Target PVC info:")
            self.logger.info(f"  Storage Class: {self.new_storageclass}")
            self.logger.info(f"  Size: {new_size_str}")
            self.logger.info(f"  Access Mode: {access_mode}")
            self.logger.info("")
            self.logger.info("**************************************")
            self.logger.info("** USE THIS SCRIPT AT YOUR OWN RISK **")
            self.logger.info("**************************************")
            if not self.yes_i_know_the_risk:
                self.logger.info("   -- press any key to continue --    ")
                input()

            # Get binding mode
            bind_mode = self.get_storage_class_binding_mode()
            self.logger.info(f"=== StorageClass '{self.new_storageclass}' uses binding mode: {bind_mode} ===")

            # Scale down workloads
            self.scale_down_workloads()

            if new_size_bytes > old_size_bytes:
                self.logger.info(f"=== Storage will be expanded from {old_size_str} to {self.new_size} ===")

            # Create temporary PVC
            self.logger.info(f"=== Step 2: Create new PVC with StorageClass '{self.new_storageclass}' and size '{self.new_size}' ===")
            self.create_temporary_pvc(access_mode)

            # Wait for binding if immediate mode
            if bind_mode == "Immediate":
                self.logger.info("=== Step 3: Waiting for PVC to bind (Immediate mode) ===")
                if not self.wait_for_pvc_bound(self.tmp_pvc_name):
                    raise RuntimeError("Temporary PVC failed to bind")
            else:
                self.logger.info("=== Step 3: Skipping wait (WaitForFirstConsumer mode) — binding will occur when pod is scheduled ===")

            # Create migration pod
            self.logger.info("=== Step 4: Create migration pod (triggers binding in WaitForFirstConsumer) ===")
            self.create_migration_pod()

            # Wait for pod ready
            self.logger.info("=== Step 5: Wait for migration pod to be ready ===")
            if not self.wait_for_pod_ready():
                raise RuntimeError("Migration pod failed to become ready")

            # Copy data
            self.copy_data()
            if self.pause_after_copy:
                self.logger.info(f"=== PAUSING REQUESTED BEFORE SHUTTING DOWN THE MIGRATOR POD AND DELETING THE OLD PVC - PRESS KEY TO CONTINUE ===")
                input()

            # Delete migration pod
            self.logger.info("=== Step 7: Delete migration pod ===")
            self.v1.delete_namespaced_pod(
                name=self.migrator_pod,
                namespace=self.namespace,
                grace_period_seconds=0
            )

            # Remove old PVC
            self.logger.info("=== Step 8: Remove old PVC object but keep PV ===")
            self.patch_resource('pvc', self.old_pvc_name, {'metadata': {'finalizers': None}})
            self.v1.delete_namespaced_persistent_volume_claim(
                name=self.old_pvc_name, namespace=self.namespace
            )

            # Get new PV name
            self.logger.info("=== Step 9: Get PV name of new PVC ===")
            self.new_pvc_name = self.get_pv_name()

            # Change PV reclaim policy
            self.logger.info("=== Step 10: Change PV reclaim policy to Retain to prevent deletion ===")
            self.patch_resource('pv', self.new_pvc_name,
                              {'spec': {'persistentVolumeReclaimPolicy': 'Retain'}}, is_pv=True)

            # Remove finalizers from temp PVC
            self.logger.info("=== Step 11: Remove finalizers from new PVC ===")
            self.patch_resource('pvc', self.tmp_pvc_name, {'metadata': {'finalizers': None}})

            # Delete temp PVC
            self.logger.info("=== Step 12: Delete new PVC object but keep PV ===")
            self.v1.delete_namespaced_persistent_volume_claim(
                name=self.tmp_pvc_name, namespace=self.namespace
            )

            # Remove claimRef from PV
            self.logger.info("=== Step 13: Remove claimRef from PV so it can be rebound ===")
            self.patch_resource('pv', self.new_pvc_name, {'spec': {'claimRef': None}}, is_pv=True)

            # Create final PVC
            self.logger.info("=== Step 14: Create PVC with original name bound to new PV ===")
            self.create_final_pvc(access_mode)

            # Wait for final PVC to bind
            self.logger.info("=== Step 15: Wait for new PVC to bind ===")
            if not self.wait_for_pvc_bound(self.old_pvc_name):
                raise RuntimeError("Final PVC failed to bind")

            self.logger.info(f"=== PVC '{self.old_pvc_name}' migration completed successfully! ===")
            self.logger.info(f"  Old: StorageClass={old_sc}, Size={old_size}")
            self.logger.info(f"  New: StorageClass={self.new_storageclass}, Size={self.new_size}")

            # Scale up workloads
            self.scale_up_workloads()

            self.logger.info("=== Migration completed successfully! ===")

        except Exception as e:
            self.logger.error(f"Migration failed: {e}")
            self.cleanup()
            raise
        finally:
            self.cleanup()

def opt2bool(opt):
    if isinstance(opt, bool):
        return opt
    elif opt.lower() in ['true', 'yes', 'ok', '1']:
        return True
    elif opt.lower() in ['false', 'no', 'nok', '0']:
        return False
    else:
        raise ArgumentTypeError(f"Cannot convert {opt} into a boolean value.")

def main():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)-5.5s %(message)s'
    )
    logger = logging.getLogger(__name__)

    p = configargparse.ArgParser()
    p.add("--namespace",
        env_var="NAMESPACE",
        default=None,
        required=True,
        help='Namespace the PVC is located.',
    )
    p.add("--pvc_name",
        env_var="PVC_NAME",
        default=None,
        required=True,
        help='Name of the PVC to migrate.',
    )
    p.add("--new_storageclass",
        env_var="NEW_STORAGECLASS",
        default=None,
        required=False,
        help='Optional: Storage class the PVC will be migrated to.',
    )
    p.add("--new_size",
        env_var="NEW_SIZE",
        default=None,
        required=False,
        help='Optional: Target size for the PVC.',
    )
    p.add("--pause_after_copy",
        env_var="PAUSE_AFTER_COPY",
        default=False,
        required=False,
        type=opt2bool,
        help='Optional: Set to "True" if you want to pause the script before shutting down the migrator Pod and deleting the old PVC.',
    )
    p.add("--migrator_image",
        env_var="MIGRATOR_IMAGE",
        default="alpine:3.23.3",
        required=False,
        help='Optional: Set the image to be used for the migrator Pod.',
    )
    p.add("--yes_i_know_the_risk",
        env_var="YES_I_KNOW_THE_RISK",
        default=False,
        type=opt2bool,
        help='Optional: Avoid the script to pause before processing the PVC by setting it to a boolean value',
    )

    args = p.parse_args()
    p.print_values()

    if (not args.new_storageclass) and (not args.new_size):
        logger.error(f"You need to define either a new storageclass or a new size.")
        sys.exit(1)

    migrator = PVCMigrator(
        namespace=args.namespace,
        old_pvc_name=args.pvc_name,
        new_storageclass=args.new_storageclass,
        new_size=args.new_size,
        pause_after_copy=args.pause_after_copy,
        migrator_image=args.migrator_image,
        yes_i_know_the_risk=args.yes_i_know_the_risk,
        logger=logger
    )

    try:
        migrator.migrate()
        logger.info("PVC migration completed.")
    except Exception as e:
        logger.exception(f"PVC migration failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
