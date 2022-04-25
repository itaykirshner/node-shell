# node-shell

## Purpose ##
Run linux commands on managed Kubernetes hosts  

## Installation ##
kubectl apply -f node-shell-daemonset.yaml  

## Usage ##
The daemonset creates a shell pod on each node of the k8s cluster.  
The shell provides direct access to the managed k8s' host shell, so you may simply "kubectl exec -it" into it (+ "chroot /host") and go wild, or you could use node-shell's built in wrapper from the outside, by running "kubectl exec -it <node-shell pod name> -- node-shell -c "\<command string\>".  
(Note: "ns" is an alias for "node-shell" and may be used as well)  
  
Examples:  
        node-shell -c "journalctl -u kubelet --since '2d ago' | less"  
        node-shell -c "docker ps -a"  
        ns -c "service kubelet restart"  
        ns -c "nslookup www.google.com"  
  
Extras:  
        node-shell logs <pod name> - View complete pod logs (supported on AKS)  
