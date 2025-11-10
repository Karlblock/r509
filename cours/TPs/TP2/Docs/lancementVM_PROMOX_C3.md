
## Guide de lancement rapide 
1) : Se rendre sur : http://proxmox-iutc3.unicaen.fr/
2) : Clone le template  r509-template-docker-etudiant
3) : rename vm TP**x**-r509-**name**
4) Lance script proxy sur bureau de la vm avec (login c3)
5) sudo apt update 
6) sudo apt install ssh
7) change mdp user ( passwd user ) 
>   exemple de mdp : NePasOublierDeRamenerLesPainsAuChocolatPourLeProfDemain
1) connect depuis ta machine physique sur la vm en ssh ( vscode like ) 
   1) ssh user@IPVMPROMOX
   2) sudo code .
   3) install extension YAML sur vscode
   4) Install extension kubernetes sur vscode

## Config proxy pour docker :

PARAMÈTRES PROXY
-------------------
Adresse IP   : 192.168.0.2
Port         : 3128
Authentification : OUI (requis)
Identifiants : Compte C3 de Proxmox (PAS les identifiants IUT des étudiants)

Format complet :
http://c3user:c3password@192.168.0.2:3128

NO_PROXY (réseaux à exclure) :
localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8

```bash
# Vérifier la configuration proxy de Docker
sudo systemctl show --property=Environment docker

# Si le proxy n'est pas configuré, le configurer
# REMPLACER username:password par vos identifiants !
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://username:password@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://username:password@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8"
EOF

# Recharger et redémarrer Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Tester
docker pull nginx:latest
```


### install tools kube : 

## 4. Installation de kubectl

```bash
# Téléchargement de la dernière version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Installation
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Nettoyage
rm kubectl

# Vérification
kubectl version --client
```

## 5. Installation de Kind

Kind (Kubernetes in Docker) permet de créer des clusters Kubernetes locaux.

```bash
# Téléchargement de Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Installation
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind

# Nettoyage
rm ./kind

# Vérification
kind version

## 7. Création du cluster Kind pour TP01/TP02

Créez un fichier de configuration pour Kind :

```bash
cat > kind-cluster-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
  - role: control-plane
  - role: worker
EOF
```

### Explications de la configuration

- **2 control-plane nodes** : haute disponibilité du control plane
- **1 worker node** : nœud pour exécuter les applications
- **Port forwarding 80:80 et 443:443** : permet d'accéder aux applications depuis l'extérieur
- **Label "ingress-ready=true"** : identifie le nœud avec les ports exposés pour l'Ingress Controller
- 


## 12. Vérification finale

```bash
# Vérifier tous les composants
docker --version
kubectl version --client
kind version

# Vérifier le cluster
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Vérifier le namespace de travail
kubectl config view --minify | grep namespace:

# Lister tous les pods
kubectl get pods -A
```

## Commandes utiles Kind

```bash
# Lister les clusters
kind get clusters

# Voir les nœuds du cluster
kind get nodes --name tp-cluster

# Obtenir le kubeconfig
kind get kubeconfig --name tp-cluster

# Supprimer le cluster (si nécessaire)
kind delete cluster --name tp-cluster

# Charger une image Docker dans le cluster Kind
kind load docker-image mon-image:tag --name tp-cluster
```

## Dépannage

### Problème : Les ports 80/443 sont déjà utilisés

```bash
# Vérifier quels processus utilisent les ports
sudo lsof -i :80
sudo lsof -i :443

# Arrêter Apache2 ou Nginx s'ils sont installés
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### Problème : Permission denied avec Docker

```bash
# Vérifier que vous êtes dans le groupe docker
groups | grep docker

# Si non, ajouter et redémarrer la session
sudo usermod -aG docker $USER
# Puis se déconnecter/reconnecter
```
## Auto-complétion kubectl (très utile !)

```bash
# Pour bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Recharger
source ~/.bashrc
```