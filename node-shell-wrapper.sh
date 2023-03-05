#!/bin/bash

showHelp()
{
   # Display Help
   echo "node-shell: run commands on k8s hosts"
   echo
   echo "Syntax: "
   echo "    ns -n <node-name> -c <\"command\"> - Runs a command on a the host of a node (note the quotes around the command string)."
   echo "    ns -l <pod-name> - Gets the complete logs of a pod. (docker runtime only)"
   echo "Hint: to get shell access to a node use \"ns -n <node-name> -c bash\", followed by \"chroot /host\" and then \"bash\"."
   echo
   echo "Options:"
   echo "i   Install the node-shell daemonset on this cluster."
   echo "d   Delete the node-shell daemonset from this cluster."
   echo "h   Print this help message."
   echo
}

installNodeShell()
{
echo "Installing node-shell..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-shell
  namespace: default
  labels:
    k8s-app: node-shell
spec:
  selector:
    matchLabels:
      name: node-shell
  template:
    metadata:
      labels:
        name: node-shell
    spec:
      containers:
      - image: gcr.io/iguazio/node-shell:0.2
        imagePullPolicy: IfNotPresent
        name: node-shell
        command: ["sleep", "infinity"]
        resources: {}
        stdin: true
        tty: true
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /host
          name: host-root
          readOnly: true
      dnsPolicy: ClusterFirst
      enableServiceLinks: true
      hostIPC: true
      hostNetwork: true
      hostPID: true
      preemptionPolicy: PreemptLowerPriority
      priority: 0
      restartPolicy: Always
      securityContext: {}
      terminationGracePeriodSeconds: 30
      tolerations:
      - effect: NoExecute
        operator: Exists
      - effect: NoSchedule
        operator: Exists
      volumes:
      - hostPath:
          path: /
          type: ""
        name: host-root
EOF
echo "Done."
}

deleteNodeShell() {
    echo "Removing node-shell..."
    kubectl -n default delete ds node-shell
    echo "Done."
}

showLogs() {
    # get the name of the node the pod is running on
        node=kubectl get pods -A -owide | grep $1 | awk '{print $8}'


}

# arg opts
while getopts :n:c:l:idh flag
do
    case "${flag}" in
        n) node=${OPTARG}
           ;;
        c) cmd="${OPTARG}"
           ;;
        l) pod=${OPTARG}
           node=`kubectl get pod -A -o custom-columns="POD-NAME":.metadata.name,"NAMESPACE":.metadata.namespace,"NODE":.spec.nodeName | grep $pod | awk '{print $NF}' | head -1`
           cmd="logs"
           ;;
        i) installNodeShell
           exit
           ;;
        d) deleteNodeShell
           exit
           ;;
        h) showHelp
           exit
           ;;
        *) showHelp
           exit
           ;;
    esac
done
if (( $OPTIND == 1 )); then
   showHelp
   exit
fi

# main
node_shell_pod_and_status=($(kubectl -n default get pods -o wide | grep "$node" | awk '{print $1,$3}'))

if [ "${node_shell_pod_and_status[1]}" != "Running" ]; then
    echo "node-shell pod not found or not running, exiting."
    exit 1
fi

if [ "$cmd" = "bash" ] || [ "$cmd" = "sh" ]; then
    echo "Hint: Switch to the host's root directory by running \"chroot /host\"."
    kubectl -n default exec -it ${node_shell_pod_and_status[0]} -- $cmd
elif [ "$cmd" = "logs" ]; then
    container_runtime=`kubectl get node $node -owide --no-headers | awk '{print $NF}' | awk -F '://' '{print $1}'`
    if [ "$container_runtime" != "docker" ]; then
        echo "Note: Node $node does not use docker as its container runtime. Containerd logs are not rotated, thus failing back to use kubectl's logs function."
        kubectl get pods -A -owide | grep $pod | awk '{print "kubectl logs "$2" -n "$1" $(kubectl get pod "$2" -n "$1" -o jsonpath=\x27{.spec.containers[0].name}\x27)"}' | bash
        exit
    fi
    pod_ns=`kubectl get pods -A | grep $pod | awk '{print $1}'`
    pod_cntr=`kubectl -n $pod_ns get pod $pod -o jsonpath='{.spec.containers[0].name}'`
    cmd="docker ps | grep k8s_${pod_cntr}_${pod} | awk '{print \$1}' | xargs docker logs"
fi

kubectl -n default exec -it ${node_shell_pod_and_status[0]} -- ns -c \""$cmd"\" | grep -v sh-[0-9+\.]
