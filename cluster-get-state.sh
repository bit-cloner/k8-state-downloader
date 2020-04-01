#!/bin/bash
### A script that downloads all objects from a K8 cluster and saves them in a directory per namespace.
### It omits all objects of type secret.

i=$((0))
for n in $(kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name pv,pvc,Role,configmap,sa,RoleBinding,ClusterRoleBinding,ClusterRole,ingress,service,deployment,ds,statefulset,hpa,job,cronjob --all-namespaces | grep -v 'secrets/default-token')
do
	if (( $i < 1 )); then
		namespace=$n
		i=$(($i+1))
		if [[ "$namespace" == "PersistentVolume" ]]; then
			kind=$n
			i=$(($i+1))
		fi
	elif (( $i < 2 )); then
		kind=$n
		i=$(($i+1))
	elif (( $i < 3 )); then
		name=$n
		i=$((0))
		echo "saving ${namespace} ${kind} ${name}"
		if [[ "$namespace" != "NAMESPACE" ]]; then
			mkdir -p $namespace
			kubectl get $kind -o=yaml $name -n $namespace > $namespace/$kind.$name.yaml
		fi
	fi
done