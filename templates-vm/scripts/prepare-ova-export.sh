#!/bin/bash

# Script de préparation de la VM avant export OVA
# À exécuter DANS la VM avant de l'éteindre et l'exporter

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║     Préparation de la VM pour export OVA                         ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en tant que root"
    echo "   Utilisez : sudo $0"
    exit 1
fi

echo "⚠️  Ce script va :"
echo "  • Nettoyer l'historique bash"
echo "  • Supprimer les logs"
echo "  • Nettoyer le cache APT"
echo "  • Vider les fichiers temporaires"
echo "  • Réinitialiser machine-id"
echo "  • Supprimer les clés SSH hôte"
echo "  • Remplir l'espace libre de zéros (pour compression)"
echo "  • Éteindre la VM"
echo ""
read -p "Voulez-vous continuer ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 1 : Nettoyage de l'historique"
echo "═══════════════════════════════════════════════════════════════════"

# Nettoyer l'historique de tous les utilisateurs
for user_home in /home/* /root; do
    if [ -d "$user_home" ]; then
        rm -f "$user_home/.bash_history"
        rm -f "$user_home/.zsh_history"
        rm -f "$user_home/.mysql_history"
        rm -f "$user_home/.python_history"
        echo "✓ Historique nettoyé pour $(basename $user_home)"
    fi
done

# Nettoyer l'historique de la session courante
history -c

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 2 : Nettoyage des logs"
echo "═══════════════════════════════════════════════════════════════════"

# Nettoyer les journaux systemd
journalctl --vacuum-time=1s

# Nettoyer les logs
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete
find /var/log -type f -name "*.old" -delete

# Nettoyer les logs spécifiques
rm -rf /var/log/*.log
rm -rf /var/log/*/*.log
rm -rf /var/log/journal/*

echo "✓ Logs nettoyés"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 3 : Nettoyage du cache et des paquets"
echo "═══════════════════════════════════════════════════════════════════"

# Nettoyer APT
apt-get clean
apt-get autoremove -y --purge
apt-get autoclean

# Nettoyer le cache de snap
if command -v snap &> /dev/null; then
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done
fi

echo "✓ Cache nettoyé"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 4 : Nettoyage des fichiers temporaires"
echo "═══════════════════════════════════════════════════════════════════"

# Nettoyer /tmp
rm -rf /tmp/*
rm -rf /tmp/.*  2>/dev/null || true

# Nettoyer /var/tmp
rm -rf /var/tmp/*
rm -rf /var/tmp/.* 2>/dev/null || true

# Nettoyer les fichiers Docker temporaires
if command -v docker &> /dev/null; then
    docker system prune -af --volumes 2>/dev/null || true
fi

echo "✓ Fichiers temporaires nettoyés"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 5 : Réinitialisation des identifiants uniques"
echo "═══════════════════════════════════════════════════════════════════"

# Vider le machine-id (sera régénéré au prochain boot)
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Supprimer les clés SSH de l'hôte (seront régénérées)
rm -f /etc/ssh/ssh_host_*

# Nettoyer cloud-init si présent
if command -v cloud-init &> /dev/null; then
    cloud-init clean --logs --seed
    rm -rf /var/lib/cloud/instances
    rm -rf /var/lib/cloud/instance
fi

# Supprimer les règles udev réseau persistantes
rm -f /etc/udev/rules.d/70-persistent-net.rules

echo "✓ Identifiants réinitialisés"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 6 : Nettoyage Docker et Minikube (optionnel)"
echo "═══════════════════════════════════════════════════════════════════"

read -p "Voulez-vous nettoyer les données Docker/Minikube ? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Arrêter Minikube
    if command -v minikube &> /dev/null; then
        sudo -u ${SUDO_USER:-ubuntu} minikube delete 2>/dev/null || true
    fi

    # Nettoyer Docker
    if systemctl is-active --quiet docker; then
        docker system prune -af --volumes
    fi

    echo "✓ Docker/Minikube nettoyés"
else
    echo "⊘ Docker/Minikube conservés"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 7 : Remplissage de l'espace libre avec des zéros"
echo "═══════════════════════════════════════════════════════════════════"

echo "⚠️  Cette étape peut prendre 5-10 minutes"
echo "   Elle permet une meilleure compression de l'OVA"
echo ""
read -p "Voulez-vous remplir l'espace libre ? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Synchroniser d'abord
    sync

    # Remplir l'espace libre avec des zéros
    echo "Remplissage en cours..."
    dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
    rm -f /EMPTY

    # Synchroniser à nouveau
    sync

    echo "✓ Espace libre rempli"
else
    echo "⊘ Remplissage ignoré"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 8 : Vérification finale"
echo "═══════════════════════════════════════════════════════════════════"

echo ""
echo "Résumé des nettoyages :"
echo "  ✓ Historique bash nettoyé"
echo "  ✓ Logs supprimés"
echo "  ✓ Cache APT nettoyé"
echo "  ✓ Fichiers temporaires supprimés"
echo "  ✓ machine-id vidé"
echo "  ✓ Clés SSH hôte supprimées"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  ✓ Espace libre rempli de zéros"
fi

echo ""
echo "Espace disque utilisé :"
df -h / | tail -1

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              ✅ VM PRÊTE POUR L'EXPORT !                          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Prochaines étapes :"
echo ""
echo "1️⃣  Éteindre la VM maintenant"
echo "   La VM va s'éteindre dans 10 secondes..."
echo ""
echo "2️⃣  Dans VirtualBox (sur l'hôte) :"
echo "   Fichier → Exporter un appareil virtuel"
echo "   Sélectionner cette VM"
echo "   Format : OVA 2.0"
echo "   Exporter"
echo ""
echo "3️⃣  Calculer le checksum (sur l'hôte) :"
echo "   sha256sum kubernetes-template.ova > kubernetes-template.ova.sha256"
echo ""
echo "4️⃣  Distribuer les fichiers :"
echo "   • kubernetes-template.ova"
echo "   • kubernetes-template.ova.sha256"
echo "   • README-OVA-DISTRIBUTION.txt"
echo ""

# Attendre 10 secondes avant extinction
for i in {10..1}; do
    echo -ne "Extinction dans $i secondes... \r"
    sleep 1
done

echo ""
echo "Extinction de la VM..."
shutdown -h now
