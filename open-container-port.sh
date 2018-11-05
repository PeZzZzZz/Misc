iptables -t nat -A DOCKER ! -i docker0 -p tcp -m tcp --dport <localport> -j DNAT --to-destination 172.17.0.2:<dockport>
iptables -t nat -A POSTROUTING -s 172.17.0.2/32 -d 172.17.0.2/32 -p tcp -m tcp --dport <dockport> -j MASQUERADE
iptables -A DOCKER -d 172.17.0.2/32 ! -i docker0 -o docker0 -p tcp -m tcp --dport <dockport> -j ACCEPT
