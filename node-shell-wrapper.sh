showHelp()
{
   # Display Help
   echo "node-shell: run commands on k8s hosts"
   echo
   echo "Syntax: "
   echo "    ns -n <node-name> -c <\"command\"> - Runs a command on a the host of a node (note the quotes around the command string)."
   echo "    ns -l <pod-name> - Gets the complete logs of all containers of a pod."
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
    kubectl apply -f https://iguazio-public.s3.amazonaws.com/node-shell-daemonset.yaml
    echo "Done."
}

deleteNodeShell() {
    echo "Removing node-shell..."
    kubectl delete -f https://iguazio-public.s3.amazonaws.com/node-shell-daemonset.yaml
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
           node=`kubectl get pods -A -owide | grep $pod | awk '{print $8}'`
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
    esac
done
if (( $OPTIND == 1 )); then
   showHelp
   exit
fi

# main
#echo "Will attempt to run \"$cmd\" on node $node";
node_shell_pod_and_status=($(kubectl -n default get pods -owide --no-headers | grep "$node" | awk '{print $1,$3}'))

if [ "${node_shell_pod_and_status[1]}" != "Running" ]; then
    echo "node-shell pod not found or not running, exiting."
    exit 1
fi

if [ "$cmd" = "bash" ] || [ "$cmd" = "sh" ]; then
    kubectl -n default exec -it ${node_shell_pod_and_status[0]} -- $cmd
elif [ "$cmd" = "logs" ]; then
    kubectl -n default exec -it ${node_shell_pod_and_status[0]} -- ns logs $pod | grep -v sh-[0-9+\.]
else
    kubectl -n default exec -it ${node_shell_pod_and_status[0]} -- ns -c \""$cmd"\" | grep -v sh-[0-9+\.]
fi
