#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/k8s.sh"
source "$SCRIPT_DIR/../lib/report.sh"
source "$SCRIPT_DIR/../config.yaml"

print_section "Layer 0: Infrastructure Validation"

total_tests=0
passed_tests=0
failed_tests=0
warnings=0

check_kubectl || error_exit "kubectl not found"
check_cluster || error_exit "Cannot connect to cluster"

echo ""

for test_name in \
    "Pod Readiness" \
    "PVC Binding Status" \
    "Ingress Address Assigned" \
    "k8up Schedule Validation" \
    "Node Readiness"
do
    case "$test_name" in
        "Pod Readiness")
            total_tests=$((total_tests + 1))
            print_section "Checking Pod Readiness"
            
            pods_not_running=0
            pod_table=""
            
            while IFS= read -r pod; do
                pod_name=$(echo "$pod" | cut -d' ' -f1)
                ready=$(echo "$pod" | awk '{print $2}')
                status=$(echo "$pod" | awk '{print $3}')
                
                if [[ "$status" != "Running" && "$status" != "Completed" && "$status" != "Succeeded" ]]; then
                    print_result FAIL "Pod $pod_name not ready: $status"
                    pods_not_running=$((pods_not_running + 1))
                    failed_tests=$((failed_tests + 1))
                elif [[ "$ready" != "1/1" && "$ready" != "2/2" && "$ready" != "3/3" && "$ready" != "0/0" ]]; then
                    if [[ "$ready" == *"/"* ]]; then
                        ready_num=${ready%/*}
                        total_num=${ready#*/}
                        if [ "$ready_num" -lt "$total_num" ]; then
                            print_result WARN "Pod $pod_name not fully ready: $ready"
                            warnings=$((warnings + 1))
                        fi
                    fi
                fi
                
                pod_table="$pod_table$(printf '%-50s %s %s\n' "$pod_name" "$ready" "$status")"
            done < <(kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get pods --no-headers 2>/dev/null || echo "")
            
            if [ $pods_not_running -eq 0 ]; then
                print_result PASS "All pods running properly"
                passed_tests=$((passed_tests + 1))
            fi
            ;;
        
        "PVC Binding Status")
            total_tests=$((total_tests + 1))
            print_section "Checking PVC Binding Status"
            
            pending_pvcs=0
            pvc_table=""
            
            while IFS= read -r pvc; do
                pvc_name=$(echo "$pvc" | cut -d' ' -f1)
                status=$(echo "$pvc" | awk '{print $2}')
                
                if [[ "$status" != "Bound" ]]; then
                    print_result FAIL "PVC $pvc_name not bound: $status"
                    pending_pvcs=$((pending_pvcs + 1))
                    failed_tests=$((failed_tests + 1))
                fi
                
                pvc_table="$pvc_table$(printf '%-50s %s\n' "$pvc_name" "$status")"
            done < <(kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get pvc --no-headers 2>/dev/null || echo "")
            
            if [ $pending_pvcs -eq 0 ]; then
                print_result PASS "All PVCs bound"
                passed_tests=$((passed_tests + 1))
            fi
            ;;
        
        "Ingress Address Assigned")
            total_tests=$((total_tests + 1))
            print_section "Checking Ingress Status"
            
            no_address=0
            ingress_table=""
            
            while IFS= read -r ingress; do
                ingress_name=$(echo "$ingress" | cut -d' ' -f1)
                hosts=$(echo "$ingress" | awk '{print $2}')
                address=$(echo "$ingress" | awk '{print $3}')
                
                if [[ "$address" == "<none>" || "$address" == "" ]]; then
                    print_result FAIL "Ingress $ingress_name has no address"
                    no_address=$((no_address + 1))
                    failed_tests=$((failed_tests + 1))
                fi
                
                ingress_table="$ingress_table$(printf '%-50s %s %s\n' "$ingress_name" "$hosts" "$address")"
            done < <(kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get ingress --no-headers 2>/dev/null || echo "")
            
            if [ $no_address -eq 0 ]; then
                print_result PASS "All ingresses have addresses"
                passed_tests=$((passed_tests + 1))
            fi
            ;;
        
        "k8up Schedule Validation")
            total_tests=$((total_tests + 1))
            print_section "Checking k8up Backup Schedules"
            
            missing_schedules=0
            
            if kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get schedule.k8up.io &>/dev/null; then
                schedule_count=$(kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get schedule.k8up.io --no-headers 2>/dev/null | wc -l)
                
                if [ "$schedule_count" -ge 1 ]; then
                    print_result PASS "k8up schedules found: $schedule_count"
                    passed_tests=$((passed_tests + 1))
                else
                    print_result WARN "No k8up schedules found"
                    warnings=$((warnings + 1))
                fi
            else
                print_result WARN "k8up Schedule CRD not installed"
                warnings=$((warnings + 1))
            fi
            ;;
        
        "Node Readiness")
            total_tests=$((total_tests + 1))
            print_section "Checking Node Status"
            
            not_ready_nodes=0
            
            while IFS= read -r node; do
                node_name=$(echo "$node" | awk '{print $1}')
                status=$(echo "$node" | awk '{print $2}')
                
                if [[ "$status" != "Ready" ]]; then
                    print_result FAIL "Node $node_name not ready: $status"
                    not_ready_nodes=$((not_ready_nodes + 1))
                    failed_tests=$((failed_tests + 1))
                fi
            done < <(kubectl --kubeconfig="$KUBE_CONFIG" get nodes --no-headers 2>/dev/null || echo "")
            
            if [ $not_ready_nodes -eq 0 ]; then
                print_result PASS "All nodes ready"
                passed_tests=$((passed_tests + 1))
            fi
            ;;
    esac
done

summarize_results $total_tests $passed_tests $failed_tests $warnings "Layer 0 - Infrastructure Tests"

exit $?