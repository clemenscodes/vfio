{
  pkgs,
  config,
}: let
  inherit (config.vfio) vm vnc;
  inherit (vnc) host guest;
in
  pkgs.writeShellScriptBin "vnc.sh" ''
    GUEST_IP="${guest.ip}"
    GUEST_PORT="${builtins.toString guest.port}"
    HOST_PORT="${builtins.toString host.port}"
    if [ "$1" = "${vm}" ]; then
      iptables -A FORWARD -s ${host.ip}/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
      if [ "$2" = "stopped" ] || [ "$2" = "reconnect" ]; then
       iptables -D FORWARD -o virbr0 -p tcp -d $GUEST_IP --dport $GUEST_PORT -j ACCEPT
       iptables -t nat -D PREROUTING -p tcp --dport $HOST_PORT -j DNAT --to $GUEST_IP:$GUEST_PORT
      fi
      if [ "$2" = "start" ] || [ "$2" = "reconnect" ]; then
       iptables -I FORWARD -o virbr0 -p tcp -d $GUEST_IP --dport $GUEST_PORT -j ACCEPT
       iptables -t nat -I PREROUTING -p tcp --dport $HOST_PORT -j DNAT --to $GUEST_IP:$GUEST_PORT
      fi
    fi
  ''
