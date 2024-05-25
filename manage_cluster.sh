#!/bin/bash

action="$1"

if [ "$action" == "start" ]; then
    # Start commands
    kubectl uncordon worker1
    kubectl uncordon worker2
    kubectl uncordon controller1
    kubectl uncordon controller2
    kubectl uncordon controller3

    kubectl scale deployment --all --replicas=1 -n default
    kubectl scale deployment --all --replicas=1 -n argocd
elif [ "$action" == "startfull" ]; then
    # Start commands
    kubectl uncordon worker1 -v9
    kubectl uncordon worker2 -v9
    kubectl uncordon controller1 -v9
    kubectl uncordon controller2 -v9
    kubectl uncordon controller3 -v9

    kubectl scale deployment --all --replicas=1 -n default -v9
    kubectl scale deployment --all --replicas=1 -n argocd -v9
elif [ "$action" == "stop" ]; then
    # Stop commands
    kubectl scale deployment --all --replicas=0 -n default
    kubectl scale deployment --all --replicas=0 -n argocd

    kubectl drain worker1 --ignore-daemonsets --delete-local-data
    kubectl drain worker2 --ignore-daemonsets --delete-local-data

    kubectl cordon worker1
    kubectl cordon worker2
    kubectl cordon controller1
    kubectl cordon controller2
    kubectl cordon controller3
elif [ "$action" == "stopfull" ]; then
    # Stop commands
    kubectl scale deployment --all --replicas=0 -n default -v9
    kubectl scale deployment --all --replicas=0 -n argocd -v9

    kubectl drain worker1 --ignore-daemonsets --delete-local-data -v9
    kubectl drain worker2 --ignore-daemonsets --delete-local-data -v9

    kubectl cordon worker1 -v9
    kubectl cordon worker2 -v9
    kubectl cordon controller1 -v9
    kubectl cordon controller2 -v9
    kubectl cordon controller3 -v9
else
    echo "Invalid action. Please use 'start' or 'stop'."
    exit 1
fi