# How to get current state of Kuberntes cluster as Yaml files

## Problem
When a team of people are working on a Kubernetes cluster it can be difficult to not overwrite each others config. when each individual applies config to the cluster they might overwrite or delete config applied by others. What are the solutions that can combat this problem?
## Solution 1 
Always apply kuberntes config through a CI/CD system where a build agent runs kubectl commands leveraging a centralised git repo. Following typical development practices like crating a branch and merging into master will keep kuberntes config consistant. But this approach might not work in all cases. This approach doesn't have a quick feedback loop. Users have to wait for the build agent to pipeline to complete a sequnce of steps like cloning a repo fetching Kuberntes credentials and finally applying. 
## Solution 2
Always download the current state of kuberntes cluster before starting to work on it. If the entire team follows this practice conflicting changes can be avoided. Ofcourse there is a risk of conflict when two of the team members start to work on a kuberntes cluster at the same time. Hence this approach is not suitable for big teams. Lets look at how such a solution can be implemented. By creating a shell script with carefully crafted kubectl commands it is possible to download the current state of a kuberntes cluster as organised yaml files.The following shell script will download all objects and organises them in folder per namespace. It ignore system obkects like kube-system, secrets.

> Disclaimer:
> This shell script is inspired from of a script from stack overflow. Unfortunately I lost the link to original script.

```sh
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
```
Lets take a look at key comands
```sh
for n in $(kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name pv,pvc,Role,configmap,sa,RoleBinding,ClusterRoleBinding,ClusterRole,ingress,service,deployment,ds,statefulset,hpa,job,cronjob --all-namespaces | grep -v 'secrets/default-token')```
```
This command gets the names of objects from all namespaces ignoring objects of type secret. 

```sh
mkdir -p $namespace
kubectl get $kind -o=yaml $name -n $namespace > $namespace/$kind.$name.yaml
```
These commands create direcotries with namespace names and gets inividual objects from the names fetched earlier. Saves them as yaml files. 

The result is a dump of current state of the cluster in yaml files that is ready to be modified and reapplied.

This comes in handy to keep a git repository synced with the state of a cluster. Thus enabling teams to work on config without conflicts. 

