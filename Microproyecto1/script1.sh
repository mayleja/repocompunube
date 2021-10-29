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
  server_name: vm1                                                                                       
  enabled: true                                                                                                     
  member_config:                                                                                                    
  - entity: storage-pool                                                                                              
    name: local                                                                                                       
    key: source                                                                                                       
    value: ""                                                                                                         
    description: '"source" property for storage pool "local"'                                                         
  cluster_address: 192.168.100.30:8443                                                                               
  cluster_certificate: "$certificado"                                              
  server_address: 192.168.100.10:8443   
  cluster_password: admin                                                                                              
EOF

echo "creacion de contenedores"
sudo lxc launch ubuntu:18.04 web1 --target vm1 < /dev/null
sleep 5
sudo lxc launch ubuntu:18.04 webaux1 --target vm1 < /dev/null
sleep 5

echo "instalando y configurando apache2"
lxc exec web1 -- apt-get update
lxc exec web1 -- apt-get install apache2 -y
lxc exec web1 -- systemctl enable apache2

echo "copiando index web1"
lxc file push /vagrant/index1.html web1/var/www/html/index.html

echo "iniciamos apache web1 "
lxc exec web1 -- systemctl start apache2

echo “configurando contenedor webaux1”
echo "instalando y configurando apache2"
lxc exec webaux1 -- apt-get update
lxc exec webaux1 -- apt-get install apache2 -y
lxc exec webaux1 -- systemctl enable apache2

echo "copiando index webaux1"
lxc file push /vagrant/indexaux1.html webaux1/var/www/html/index.html

echo "iniciamos apache webaux1 "
lxc exec webaux1 -- systemctl start apache2
