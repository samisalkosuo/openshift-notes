
function firewallCommandUsage
{
    echo "Usage: $0 firewall <command>"
    echo ""
    echo "Command:"
    echo "  open  - Open ports."
    echo "  close - Close ports."
    exit 1
}


function firewallCommand
{
    if [[ "$1" == "" ]]; then
        firewallCommandUsage
    fi
    case "$1" in
        open)
            openPorts
        ;;
        close)
            closePorts
        ;;
        *)
            firewallCommandUsage
        ;;
    esac

}

function openPorts
{
  echo "Open NTP port..."
  firewall-cmd --add-port=123/udp
  echo "Open DNS ports..."
  firewall-cmd --add-port=53/udp --add-port=53/tcp
  echo "Open DHCP/TFTP ports..."
  firewall-cmd --add-port=67/udp --add-port=69/udp
  echo "Open HTTP/HTTPS ports..."
  firewall-cmd --add-port=80/tcp --add-port=443/tcp --add-port=8080/tcp 
  echo "Open OpenShift API ports..."
  firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 
  #persist firewall settings
  firewall-cmd --runtime-to-permanent

}

function closePorts
{
  echo "Close NTP port..."
  firewall-cmd --remove-port=123/udp
  echo "Close DNS ports..."
  firewall-cmd --remove-port=53/udp --remove-port=53/tcp
  echo "Close DHCP/TFTP ports..."
  firewall-cmd --remove-port=67/udp --remove-port=69/udp
  echo "Close HTTP/HTTPS ports..."
  firewall-cmd --remove-port=80/tcp --remove-port=443/tcp --remove-port=8080/tcp
  echo "Close OpenShift API ports..."
  firewall-cmd --remove-port=6443/tcp --remove-port=22623/tcp 
  #persist firewall settings
  firewall-cmd --runtime-to-permanent

}
