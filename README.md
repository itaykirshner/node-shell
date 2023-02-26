# node-shell

## Purpose ##
Run shell commands on Kubernetes hosts  

## Installation ##
`kubectl apply -f node-shell-daemonset.yaml`, or via the external utility with "ns -i"

## Uninstall ##
`kubectl delete -f node-shell-daemonset.yaml`, or via the external utility with "ns -d"

## Usage ##
The daemonset creates a shell pod on each node of the k8s cluster, in the default namespace, prefixed with "node-shell".  
The shell provides direct access to the k8s host's shell, so you may simply `kubectl exec -it` into it (+ `chroot /host`) and go wild, or you could use node-shell's built in wrapper from the outside, by running `kubectl exec -it <node-shell pod name> -- node-shell -c "<command string>"`.  
The node-shell pods provide DNS and network diagnostics commands as well, such as `nslookup`, `ping` etc.  
(Note: `ns` is an alias for `node-shell` and may be used as well) 
  
Examples:  
        `node-shell -c "journalctl -u kubelet --since '2d ago' | less"`  
        `node-shell -c "docker ps -a"`  
        `ns -c "service kubelet restart"`  
        `ns -c "nslookup www.google.com"`  
  
Extras:  
        `node-shell logs <pod name> - View complete pod logs (supported on AKS)`  

## External Utility ##
In version 0.2 a small external utility was added to make things a even simpler, so using node-shell is now easier to understand, and no longer requires figuring out the names of the node-shell pod running on specific nodes.
The utility, named node-shell-wrapper.sh, is meant to be installed in <dir in system path>/ns (e.g. /usr/local/bin/ns). Here's its help message to shed light on usage:
```
node-shell: run commands on k8s hosts

Syntax:
    ns -n <node-name> -c <"command"> - Runs a command on a the host of a node (note the quotes around the command string).
    ns -l <pod-name> - Gets the complete logs of all containers of a pod.
Hint: to get shell access to a node use "ns -n <node-name> -c bash", followed by "chroot /host" and then "bash".

Options:
i   Install the node-shell daemonset on this cluster.
d   Delete the node-shell daemonset from this cluster.
h   Print this help message.
```
