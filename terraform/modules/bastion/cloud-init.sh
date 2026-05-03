#!/bin/bash
# Minimal OpenVPN community server bootstrap for Amazon Linux 2023 (arm64).
# Runs once at instance launch. Idempotent.
# NOTE: -e is intentionally OMITTED so a failure in OpenVPN setup later
# doesn't prevent SSM agent from starting — we still want a way back in.
set -uxo pipefail

# (1) SSM first — if anything below this fails we keep a debugging path.
# AL2023 has amazon-ssm-agent pre-installed; just make sure it's enabled.
systemctl enable --now amazon-ssm-agent || true

# (2) Packages we actually need. NO dnf update — it triggers a known
# curl/curl-minimal conflict on AL2023 that aborts cloud-init.
# --allowerasing handles transitive conflicts gracefully.
dnf -y --allowerasing install openvpn iptables-services tar curl

# IP forwarding for VPN clients to reach the internet via the bastion.
cat > /etc/sysctl.d/99-openvpn.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/99-openvpn.conf

# NAT VPN traffic out of the bastion's public interface.
PRIMARY_IFACE=$(ip route show default | awk '{print $5; exit}')
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "${PRIMARY_IFACE}" -j MASQUERADE
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables

# easy-rsa from upstream (not in AL2023 default repos).
EASYRSA_VERSION=3.1.7
if [ ! -d /etc/openvpn/easy-rsa/pki ]; then
  curl -sL "https://github.com/OpenVPN/easy-rsa/releases/download/v${EASYRSA_VERSION}/EasyRSA-${EASYRSA_VERSION}.tgz" \
    | tar -xz -C /etc/openvpn
  ln -sfn "/etc/openvpn/EasyRSA-${EASYRSA_VERSION}" /etc/openvpn/easy-rsa

  cd /etc/openvpn/easy-rsa
  ./easyrsa init-pki
  EASYRSA_BATCH=1 ./easyrsa build-ca nopass
  EASYRSA_BATCH=1 ./easyrsa gen-req server nopass
  EASYRSA_BATCH=1 ./easyrsa sign-req server server
  EASYRSA_BATCH=1 ./easyrsa gen-req client1 nopass
  EASYRSA_BATCH=1 ./easyrsa sign-req client client1
  EASYRSA_BATCH=1 ./easyrsa gen-dh
fi

cat > /etc/openvpn/server/server.conf <<'EOF'
port 1194
proto udp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
EOF

systemctl enable --now openvpn-server@server

# Helper: prints a self-contained .ovpn for client1 to stdout.
# Run via SSM session: `sudo /usr/local/bin/get-ovpn-config > client.ovpn`
cat > /usr/local/bin/get-ovpn-config <<'EOF'
#!/bin/bash
set -euo pipefail
PKI=/etc/openvpn/easy-rsa/pki
PUBLIC_IP=$(curl -fsS http://169.254.169.254/latest/meta-data/public-ipv4 \
  -H "X-aws-ec2-metadata-token: $(curl -fsS -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 60')")
cat <<INNER
client
dev tun
proto udp
remote ${PUBLIC_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
<ca>
$(cat "${PKI}/ca.crt")
</ca>
<cert>
$(cat "${PKI}/issued/client1.crt")
</cert>
<key>
$(cat "${PKI}/private/client1.key")
</key>
INNER
EOF
chmod +x /usr/local/bin/get-ovpn-config
