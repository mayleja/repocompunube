echo "instalando net-tools"
sudo apt-get install net-tools -y

echo "instalando lxd"
sudo snap install lxd

echo “leyendo certificado”
certificado=$(cat "/vagrant/cluster.txt") 

echo “ejecutando preseed”
cat <<EOF | sudo lxd init --preseed
config: {}                                                                                                        
networks: []                                                                                                      
storage_pools: []                                                                                                 
profiles: []                                                                                                      
cluster:                                                                                                            
  server_name: vm2                                                                                       
  enabled: true                                                                                                     
  member_config:                                                                                                    
  - entity: storage-pool                                                                                              
    name: local                                                                                                       
    key: source                                                                                                       
    value: ""                                                                                                         
    description: '"source" property for storage pool "local"'                                                         
  cluster_address: 192.168.100.30:8443                                                                               
  cluster_certificate: "$certificado"                                              
  server_address: 192.168.100.20:8443   
  cluster_password: admin                                                                                              
EOF

echo "creacion de contenedores"
sudo lxc launch ubuntu:18.04 web2 --target vm2 < /dev/null
sleep 5
sudo lxc launch ubuntu:18.04 webaux2 --target vm2 < /dev/null
sleep 5

echo "instalando y configurando apache2"
lxc exec web2 -- apt-get update
lxc exec web2 -- apt-get install apache2 -y
lxc exec web2 -- systemctl enable apache2

echo "copiando index web2"
lxc file push /vagrant/index2.html web2/var/www/html/index.html

echo "iniciamos apache web2 "
lxc exec web2 -- systemctl start apache2

echo “configurando contenedor webaux2”
echo "instalando y configurando apache2"
lxc exec webaux2 -- apt-get update
lxc exec webaux2 -- apt-get install apache2 -y
lxc exec webaux2 -- systemctl enable apache2

echo "copiando index webaux2 "
lxc file push /vagrant/indexaux2.html webaux2/var/www/html/index.html

echo "iniciamos apache webaux2 "
lxc exec webaux2 -- systemctl start apache2

echo "reiniciamos haproxy"
lxc exec haproxy -- systemctl restart haproxy