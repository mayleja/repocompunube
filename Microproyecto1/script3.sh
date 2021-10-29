echo "instalando net-tools"
sudo apt-get install net-tools -y

echo "instalando lxd"
sudo snap install lxd

echo “creando cluster”

cat <<EOF | lxd init --preseed
config:                                                                                                      
  core.https_address: 192.168.100.30:8443                                                                     
  core.trust_password: admin                                                                               
networks:                                                                                                  
- config:                                                                                                      
    bridge.mode: fan                                                                                           
    fan.underlay_subnet: 192.168.100.0/24                                                                               
  description: ""                                                                                            
  name: lxdfan0                                                                                              
  type: ""                                                                                                 
storage_pools:                                                                                             
- config: {}                                                                                                 
  description: ""                                                                                            
  name: local                                                                                                
  driver: dir                                                                                              
profiles:                                                                                                  
- config: {}                                                                                                 
  description: ""                                                                                            
  devices:                                                                                                     
    eth0:                                                                                                        
      name: eth0                                                                                                 
      network: lxdfan0                                                                                           
      type: nic                                                                                                
    root:                                                                                                        
      path: /                                                                                                    
      pool: local                                                                                                
      type: disk                                                                                             
  name: default                                                                                            
cluster:                                                                                                     
  server_name: vm3                                                                                 
  enabled: true                                                                                              
  member_config: []                                                                                          
  cluster_address: ""                                                                                        
  cluster_certificate: ""                                                                                    
  server_address: ""                                                                                         
  cluster_password: ""                                                                                       
EOF

echo "generando certificado"
sed ':a;N;$!ba;s/\n/\n\n/g' /var/snap/lxd/common/lxd/cluster.crt > /vagrant/cluster.txt

echo "creacion de contenedor"
lxc launch ubuntu:18.04 haproxy --target vm3 < /dev/null
sleep 5

echo "instalando y configurando haproxy"
lxc exec haproxy -- apt-get update
lxc exec haproxy -- apt-get install haproxy -y

echo "habilitamos haproxy "
lxc exec haproxy -- systemctl enable haproxy

echo "copiando el config de haproxy"
lxc file push /vagrant/haproxy.cfg haproxy/etc/haproxy/haproxy.cfg

echo "copiando el mensaje de error personalizado"
lxc file push /vagrant/503.http haproxy/etc/haproxy/errors/503.http

echo "iniciamos haproxy"
lxc exec haproxy -- systemctl start haproxy

echo "redireccionamos puertos"
lxc config device add haproxy http proxy listen=tcp:0.0.0.0:1080 connect=tcp:127.0.0.1:80
