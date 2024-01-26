# VPN Setup

A wireguard VPN is used to connect to the network

### Usage

To setup the vpn server, run the ansible playbook.

```sh
ansible-playbook -i inventory.ini playbook.yml
```

By default, 41 wireguard configurations are created. They are generated via the `user_gen.py` script, which contains 3 global variables. `infra_count`, `blue_count`, and `red_count`. These determine how many configurations will be created. By default, 1 infra config, 10 blue team, and 30 red team configurations are generated. These can be changed, and the ansible playbook will run it.

Each user must use a unique configuration file. Users connect with the following command

```sh
# Via file
wg-quick up <config file>

# Via /etc/wireguard
mv <config file> /etc/wireguard
wg-quick ip <config number>
```

### Wireguard configuration

This is automated via ansible, but the following commands are run to setup the server

```shell
sudo apt install -y wireguard

wg genkey | tee privatekey | wg pubkey > publickey

echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

wg set wg0 peer [clientpublickey] allowed-ips [IP]

wg-quick up server
```

Server Configuration Template

```
[Interface]
Address = 10.0.50.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = server_private_key
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE
```

Client Configuration Template

```
[Interface]
PrivateKey = client_private_key
Address = 10.0.50.2/24

[Peer]
PublicKey = server_public_key
Endpoint = 54.90.13.247:51820
AllowedIPs = 10.0.0.0/16
```
