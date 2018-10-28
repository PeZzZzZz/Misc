if [[ $1 = "init" ]]; then
  echo "[+] Kluster  init..."
  kubeadm init --pod-network-cidr=10.224.0.0/16 > log.txt 2>&1 
  cp /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
  echo "       !!! Wait 40s for system pods up !!!"
  sleep 40
  echo "[+] Weave init..."
  for i in weave.yaml ; do kubectl create -f $i >> log.txt 2>&1; done
  echo "       !!! Wait 20s for weave pods up !!!"
  sleep 20
  echo "[+] Weave pods up"
  echo "[+] System pods up"
  echo -e "[+] Join command:\n `cat log.txt |grep \"kubeadm join\")`"
fi
if [[ "$1" == "reset" ]]; then 
  echo 'y' |kubeadm reset >log.txt 2>&1
  systemctl stop kubelet >>log.txt 2>1
  systemctl stop docker >>log.txt 2>1
  rm -rf /var/lib/cni/ >>log.txt 2>1
  rm -rf /var/lib/kubelet/* >>log.txt 2>1
  rm -rf /etc/cni/ >>log.txt 2>1
  ifconfig cni0 down >>log.txt 2>1
  ifconfig flannel.1 down >>log.txt 2>1
  ifconfig docker0 down >>log.txt 2>1
  ip link delete cni0 >>log.txt 2>1
  ip link delete flannel.1 >>log.txt 2>1
  systemctl start docker >>log.txt 2>1
  systemctl start kubelet >>log.txt 2>1
fi
if [[ $1 = "mnc" ]]; then ## master nginx create
  rm log.txt
  echo "[+] Nginx init..."
  for i in stark-pv.yaml stark-pvc.yaml stark-deployment-nginx.yaml stark-svc-nginx.yaml; do kubectl create -f $i >>log.txt 2>&1 ; done; # bash expose.sh 
  echo "[+] Nginx network and pods up"
  echo "       *** Nginx server is up. Enjoy ***"
fi 
if [[ $1 = "nc" ]]; then ## nginx create
  rm log.txt
  echo "[+] Nginx init..."
  for i in stark-deployment-nginx.yaml ; do kubectl create -f $i >>log.txt 2>&1 ; done; bash expose.sh 
  echo "[+] Nginx pods up"
  echo "       *** Nginx server is up. Enjoy ***"
fi 
if [[ $1 = "mnd" ]]; then ## master nginx delete
  rm log.txt
  echo "[+] Nginx delete..."
  for i in stark-deployment-nginx.yaml stark-pv.yaml stark-pvc.yaml ; do kubectl delete -f $i >>log.txt 2>&1; done
  kubectl delete svc nginx-service
  echo "[+] Nginx network and pods deleted"
fi
if [[ $1 = "nd" ]]; then ## nginx delete
  rm log.txt
  echo "[+] Nginx delete..."
  for i in stark-deployment-nginx.yaml ; do kubectl delete -f $i >>log.txt 2>&1; done
  kubectl delete svc nginx-service
  echo "[+] Nginx pods deleted"
fi
######### LOG #########
## $1 = log opt
## $2 = pod name or expression in name
## $3 = watch opt
if [[ "$1" == "log" ]]; then ## logs from specific pod
  if [[ "$3" =~ [0-9] ]]; then
    if [[ "$4" == "w" ]]; then
      watch -n 3 "kubectl logs $(kubectl get pods --all-namespaces |awk '{print$2}' |grep "$2" |sed -n "$3"p) |tail -f"
    else
      kubectl logs $(kubectl get pods --all-namespaces |awk '{print$2}' |grep "$2" |sed -n "$3"p) |tail
    fi
  fi
fi
######### MONIT #########
if [[ "$1" == "mon" ]]; then ## monit from pods,nodes
  if [[ "$2" == "n" ]]; then
    if [[ "$3" == "w" ]]; then
      watch "kubectl  get nodes -o wide |awk '{ printf \"%-20s %14s %14s %14s %14s\n\", \$1, \$2, \$3, \$6, \$7 }'"
    else
      kubectl  get nodes -o wide |awk '{ printf "%-20s %14s %14s %14s %14s\n", $1, $2, $3, $6, $7 }'
    fi
  elif [[ "$2" == "p" ]]; then
    if [[ "$3" == "w" ]]; then    
      watch "kubectl  get pods -o wide |awk '{ printf \"%-20s %14s %14s %14s %14s\n\", \$1, \$2, \$3, \$6, \$7 }'"
    else
      kubectl  get pods -o wide |awk '{ printf "%-20s %14s %14s %14s %14s\n", $1, $2, $3, $6, $7 }'
    fi
  elif [[ "$2" == "s" ]]; then
    if [[ "$3" == "w" ]]; then    
      watch "kubectl  get pods -o wide --all-namespaces |awk '{ printf \"%-14s %45s %14s %14s %14s %14s\n\", \$1, \$2, \$3, \$4, \$7, \$8 }'"
    else
      kubectl  get pods -o wide --all-namespaces |awk '{ printf "%14s %-45s %14s %14s %14s %14s\n", $1, $2, $3, $4, $7, $8 }'
    fi
  fi
fi
####### EXEC #####
if [[ "$1" == "sh" ]]; then
  if [[ $3 =~ [0-9] ]]; then
    kubectl exec -it $(kubectl get pods | awk '{print$1}' |grep "$2"| sed -n "$3"p) -- bash
  fi
fi
## iptables -P FORWARD ACCEPT
