#!/bin/bash

#==============================================================================
# Script d'Installation Automatique - Fidaous Pro Cabinet Comptable
# Version: 1.0.0
# Système: Debian 12 (Bookworm)
# Description: Installation complète avec LAMP, Nextcloud et WhatsApp Business
#==============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuration
DOMAIN_NAME=""
ADMIN_EMAIL=""
MYSQL_ROOT_PASSWORD=""
FIDAOUS_DB_PASSWORD=""
NEXTCLOUD_ADMIN_PASSWORD=""
INSTALL_DIR="/var/www/html/fidaous-pro"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
LOG_FILE="/var/log/fidaous-pro-install.log"

# Version des composants
PHP_VERSION="8.2"
NODEJS_VERSION="18"

#==============================================================================
# Fonctions utilitaires
#==============================================================================

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERREUR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[AVERTISSEMENT]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en tant que root (sudo)"
    fi
}

check_debian_version() {
    if ! grep -q "Debian GNU/Linux 12" /etc/os-release; then
        warning "Ce script est optimisé pour Debian 12. Continuez-vous ?"
        read -p "Tapez 'oui' pour continuer: " confirm
        if [[ $confirm != "oui" ]]; then
            exit 1
        fi
    fi
}

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

#==============================================================================
# Configuration initiale
#==============================================================================

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                     FIDAOUS PRO - INSTALLATION                      ║"
    echo "║                   Cabinet Comptable - Maroc                         ║"
    echo "║                        Version 1.0.0                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

collect_configuration() {
    log "Collecte des informations de configuration"
    
    echo "Configuration de l'installation Fidaous Pro"
    echo "============================================="
    echo
    
    # Nom de domaine
    while [[ -z "$DOMAIN_NAME" ]]; do
        read -p "Nom de domaine (ex: fidaous-pro.ma): " DOMAIN_NAME
        if [[ ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
            echo "Format de domaine invalide"
            DOMAIN_NAME=""
        fi
    done
    
    # Email administrateur
    while [[ -z "$ADMIN_EMAIL" ]]; do
        read -p "Email administrateur: " ADMIN_EMAIL
        if [[ ! "$ADMIN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Format d'email invalide"
            ADMIN_EMAIL=""
        fi
    done
    
    # Génération des mots de passe
    MYSQL_ROOT_PASSWORD=$(generate_password)
    FIDAOUS_DB_PASSWORD=$(generate_password)
    NEXTCLOUD_ADMIN_PASSWORD=$(generate_password)
    
    echo
    log "Configuration collectée avec succès"
    info "Domaine: $DOMAIN_NAME"
    info "Email: $ADMIN_EMAIL"
    info "Les mots de passe ont été générés automatiquement"
}

#==============================================================================
# Installation des dépendances système
#==============================================================================

update_system() {
    log "Mise à jour du système Debian 12"
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq || error "Échec de la mise à jour des paquets"
    apt-get upgrade -y -qq || error "Échec de la mise à niveau du système"
    apt-get install -y -qq \
        curl \
        wget \
        gnupg \
        lsb-release \
        ca-certificates \
        software-properties-common \
        apt-transport-https \
        unzip \
        git \
        htop \
        nano \
        fail2ban \
        ufw \
        certbot \
        python3-certbot-apache || error "Installation des paquets de base échouée"
    
    log "Système mis à jour avec succès"
}

install_lamp_stack() {
    log "Installation de la pile LAMP (Apache, MySQL, PHP)"
    
    # Installation d'Apache
    apt-get install -y -qq apache2 apache2-utils || error "Installation d'Apache échouée"
    systemctl enable apache2
    systemctl start apache2
    
    # Configuration d'Apache
    a2enmod rewrite ssl headers deflate expires
    
    # Installation de MySQL
    apt-get install -y -qq mysql-server mysql-client || error "Installation de MySQL échouée"
    systemctl enable mysql
    systemctl start mysql
    
    # Configuration sécurisée de MySQL
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
    
    # Installation de PHP
    apt-get install -y -qq \
        php$PHP_VERSION \
        php$PHP_VERSION-fpm \
        php$PHP_VERSION-mysql \
        php$PHP_VERSION-mbstring \
        php$PHP_VERSION-xml \
        php$PHP_VERSION-gd \
        php$PHP_VERSION-curl \
        php$PHP_VERSION-zip \
        php$PHP_VERSION-intl \
        php$PHP_VERSION-bcmath \
        php$PHP_VERSION-json \
        php$PHP_VERSION-redis \
        php$PHP_VERSION-imagick \
        php$PHP_VERSION-ldap \
        php$PHP_VERSION-imap \
        libapache2-mod-php$PHP_VERSION || error "Installation de PHP échouée"
    
    # Configuration de PHP
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 512M/" /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i "s/post_max_size = .*/post_max_size = 512M/" /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i "s/;date.timezone.*/date.timezone = Africa\/Casablanca/" /etc/php/$PHP_VERSION/apache2/php.ini
    
    systemctl restart apache2
    
    log "Pile LAMP installée avec succès"
}

install_nodejs_composer() {
    log "Installation de Node.js et Composer"
    
    # Installation de Node.js
    curl -fsSL https://deb.nodesource.com/setup_$NODEJS_VERSION.x | bash -
    apt-get install -y -qq nodejs || error "Installation de Node.js échouée"
    
    # Installation de Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    chmod +x /usr/local/bin/composer
    
    log "Node.js et Composer installés avec succès"
}

#==============================================================================
# Configuration de la base de données
#==============================================================================

setup_database() {
    log "Configuration de la base de données Fidaous Pro"
    
    # Création de l'utilisateur et de la base de données
    mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE database_fidaous_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'fidaous_user'@'localhost' IDENTIFIED BY '$FIDAOUS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON database_fidaous_pro.* TO 'fidaous_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    log "Base de données configurée avec succès"
}

#==============================================================================
# Installation de Fidaous Pro
#==============================================================================

install_fidaous_pro() {
    log "Installation de l'application Fidaous Pro"
    
    # Création du répertoire d'installation
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Téléchargement ou clonage du code source
    # Note: Remplacez par l'URL réelle du repository
    # git clone https://github.com/fidaouspro/cabinet-comptable.git .
    
    # Pour cette démonstration, nous créons la structure de base
    mkdir -p {api,assets/{css,js,images,fonts},classes,config,cron,database,docs,includes,lang,logs,middleware,pages,storage/{temp,uploads,backups,cache},templates/{email,whatsapp,pdf,excel},tests,utils,webhooks,vendor}
    
    # Création des fichiers de base
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fidaous Pro - Cabinet Comptable</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #2c3e50; }
        .status { background: #d4edda; padding: 20px; border-radius: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 Fidaous Pro</h1>
        <h2>Cabinet Comptable - Maroc</h2>
        <div class="status">
            <h3>✅ Installation réussie !</h3>
            <p>L'application est maintenant prête à être configurée.</p>
        </div>
        <p>Accédez à l'interface d'administration pour terminer la configuration.</p>
    </div>
</body>
</html>
EOF
    
    # Configuration des permissions
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$INSTALL_DIR/storage"
    chmod -R 775 "$INSTALL_DIR/logs"
    
    log "Application Fidaous Pro installée"
}

#==============================================================================
# Installation de Nextcloud
#==============================================================================

install_nextcloud() {
    log "Installation de Nextcloud pour la gestion documentaire"
    
    # Téléchargement de Nextcloud
    cd /tmp
    wget -q https://download.nextcloud.com/server/releases/latest.zip -O nextcloud.zip
    unzip -q nextcloud.zip
    mv nextcloud "$NEXTCLOUD_DIR"
    
    # Configuration des permissions
    chown -R www-data:www-data "$NEXTCLOUD_DIR"
    chmod -R 755 "$NEXTCLOUD_DIR"
    
    # Création de la base de données Nextcloud
    mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'nextcloud_user'@'localhost' IDENTIFIED BY '$(generate_password)';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    log "Nextcloud installé avec succès"
}

#==============================================================================
# Configuration d'Apache
#==============================================================================

configure_apache() {
    log "Configuration d'Apache et des Virtual Hosts"
    
    # Virtual Host pour Fidaous Pro
    cat > /etc/apache2/sites-available/fidaous-pro.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    DocumentRoot $INSTALL_DIR
    
    <Directory $INSTALL_DIR>
        AllowOverride All
        Require all granted
        Options -Indexes
    </Directory>
    
    # Redirection API
    RewriteEngine On
    RewriteRule ^api/(.*)$ api/endpoints.php [QSA,L]
    RewriteRule ^webhooks/(.*)$ webhooks/\$1.php [QSA,L]
    
    # Logs
    ErrorLog \${APACHE_LOG_DIR}/fidaous-pro-error.log
    CustomLog \${APACHE_LOG_DIR}/fidaous-pro-access.log combined
</VirtualHost>
EOF
    
    # Virtual Host pour Nextcloud
    cat > /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    ServerName cloud.$DOMAIN_NAME
    DocumentRoot $NEXTCLOUD_DIR
    
    <Directory $NEXTCLOUD_DIR>
        AllowOverride All
        Require all granted
        Options -Indexes
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/nextcloud-error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud-access.log combined
</VirtualHost>
EOF
    
    # Activation des sites
    a2ensite fidaous-pro.conf
    a2ensite nextcloud.conf
    a2dissite 000-default.conf
    
    systemctl reload apache2
    
    log "Configuration Apache terminée"
}

#==============================================================================
# Configuration SSL avec Let's Encrypt
#==============================================================================

setup_ssl() {
    log "Configuration SSL avec Let's Encrypt"
    
    # Configuration du pare-feu
    ufw --force enable
    ufw allow ssh
    ufw allow http
    ufw allow https
    
    # Obtention des certificats SSL
    certbot --apache --non-interactive --agree-tos --email "$ADMIN_EMAIL" \
        -d "$DOMAIN_NAME" -d "cloud.$DOMAIN_NAME" || warning "Échec de la configuration SSL automatique"
    
    # Configuration du renouvellement automatique
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
    
    log "Configuration SSL terminée"
}

#==============================================================================
# Configuration de la sécurité
#==============================================================================

configure_security() {
    log "Configuration de la sécurité système"
    
    # Configuration de Fail2Ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[apache-auth]
enabled = true

[apache-badbots]
enabled = true

[apache-noscript]
enabled = true

[apache-overflows]
enabled = true

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    
    systemctl enable fail2ban
    systemctl start fail2ban
    
    # Configuration des headers de sécurité Apache
    cat > /etc/apache2/conf-available/security-headers.conf << EOF
# Security Headers
Header always set X-Frame-Options DENY
Header always set X-Content-Type-Options nosniff
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"

# HSTS (uniquement si SSL est configuré)
# Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
EOF
    
    a2enconf security-headers
    systemctl reload apache2
    
    log "Sécurité système configurée"
}

#==============================================================================
# Configuration des tâches automatisées
#==============================================================================

setup_cron_jobs() {
    log "Configuration des tâches automatisées"
    
    # Création du fichier crontab pour Fidaous Pro
    cat > /etc/cron.d/fidaous-pro << EOF
# Fidaous Pro - Tâches automatisées
# Vérification des échéances (tous les jours à 6h00)
0 6 * * * www-data /usr/bin/php $INSTALL_DIR/cron/daily_tasks.php

# Rappels WhatsApp (tous les jours à 8h00)
0 8 * * * www-data /usr/bin/php $INSTALL_DIR/cron/whatsapp_reminders.php

# Synchronisation Nextcloud (toutes les heures)
0 * * * * www-data /usr/bin/php $INSTALL_DIR/cron/sync_nextcloud.php

# Sauvegarde base de données (tous les jours à 2h00)
0 2 * * * root /usr/bin/php $INSTALL_DIR/cron/backup_database.php

# Nettoyage des logs (toutes les semaines)
0 3 * * 0 root /usr/bin/php $INSTALL_DIR/cron/weekly_cleanup.php
EOF
    
    log "Tâches automatisées configurées"
}

#==============================================================================
# Finalisation et tests
#==============================================================================

create_admin_user() {
    log "Création de l'utilisateur administrateur"
    
    # Importation de la structure de base de données
    if [[ -f "$INSTALL_DIR/database/structure.sql" ]]; then
        mysql -u fidaous_user -p$FIDAOUS_DB_PASSWORD database_fidaous_pro < "$INSTALL_DIR/database/structure.sql"
    fi
    
    # Création de l'utilisateur admin avec mot de passe par défaut
    ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")
    
    mysql -u fidaous_user -p$FIDAOUS_DB_PASSWORD database_fidaous_pro <<EOF
INSERT INTO employes (matricule, nom, prenom, email, telephone, role_id, date_embauche, mot_de_passe) 
VALUES ('ADM001', 'Administrateur', 'Fidaous', '$ADMIN_EMAIL', '+212522000000', 1, CURDATE(), '$ADMIN_PASSWORD_HASH') 
ON DUPLICATE KEY UPDATE email='$ADMIN_EMAIL';
EOF
    
    log "Utilisateur administrateur créé"
}

run_tests() {
    log "Exécution des tests de vérification"
    
    # Test de connectivité Apache
    if systemctl is-active --quiet apache2; then
        info "✅ Apache est actif"
    else
        error "❌ Apache n'est pas actif"
    fi
    
    # Test de connectivité MySQL
    if systemctl is-active --quiet mysql; then
        info "✅ MySQL est actif"
    else
        error "❌ MySQL n'est pas actif"
    fi
    
    # Test d'accès aux fichiers
    if [[ -r "$INSTALL_DIR/index.html" ]]; then
        info "✅ Application Fidaous Pro accessible"
    else
        warning "❌ Problème d'accès aux fichiers Fidaous Pro"
    fi
    
    # Test de PHP
    if php -v >/dev/null 2>&1; then
        info "✅ PHP configuré (version $(php -r 'echo PHP_VERSION;'))"
    else
        error "❌ Problème avec PHP"
    fi
    
    log "Tests de vérification terminés"
}

#==============================================================================
# Affichage des informations finales
#==============================================================================

display_final_info() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION TERMINÉE AVEC SUCCÈS                ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo -e "${BLUE}🌐 ACCÈS À L'APPLICATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Application principale : http://$DOMAIN_NAME"
    echo "Nextcloud             : http://cloud.$DOMAIN_NAME"
    echo
    echo -e "${BLUE}🔐 INFORMATIONS DE CONNEXION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Email administrateur     : $ADMIN_EMAIL"
    echo "Mot de passe par défaut  : admin123"
    echo "Base de données         : database_fidaous_pro"
    echo "Utilisateur BDD         : fidaous_user"
    echo
    echo -e "${BLUE}🛡️ INFORMATIONS SÉCURISÉES${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Les mots de passe ont été sauvegardés dans : /root/fidaous-credentials.txt"
    echo
    echo -e "${YELLOW}⚠️  ACTIONS RECOMMANDÉES${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Changez le mot de passe administrateur par défaut"
    echo "2. Configurez les paramètres WhatsApp Business dans l'interface"
    echo "3. Terminez la configuration Nextcloud via l'interface web"
    echo "4. Configurez les sauvegardes automatiques"
    echo "5. Testez l'envoi d'emails et les notifications"
    echo
    echo -e "${BLUE}📋 FICHIERS DE CONFIGURATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Application : $INSTALL_DIR"
    echo "Nextcloud   : $NEXTCLOUD_DIR"
    echo "Logs        : $LOG_FILE"
    echo "Apache      : /etc/apache2/sites-available/"
    echo
    
    # Sauvegarde des informations sensibles
    cat > /root/fidaous-credentials.txt << EOF
FIDAOUS PRO - INFORMATIONS DE CONFIGURATION
===========================================
Date d'installation: $(date)
Domaine: $DOMAIN_NAME
Email administrateur: $ADMIN_EMAIL

MOTS DE PASSE GÉNÉRÉS:
- MySQL root: $MYSQL_ROOT_PASSWORD
- Base Fidaous Pro: $FIDAOUS_DB_PASSWORD
- Nextcloud admin: $NEXTCLOUD_ADMIN_PASSWORD

CHEMINS IMPORTANTS:
- Application: $INSTALL_DIR
- Nextcloud: $NEXTCLOUD_DIR
- Logs: $LOG_FILE

PREMIÈRE CONNEXION:
- URL: http://$DOMAIN_NAME
- Email: $ADMIN_EMAIL
- Mot de passe: admin123 (À CHANGER IMMÉDIATEMENT)
EOF
    
    chmod 600 /root/fidaous-credentials.txt
    
    echo -e "${GREEN}Installation terminée avec succès !${NC}"
    echo "Consultez la documentation complète dans $INSTALL_DIR/docs/"
}

#==============================================================================
# Fonction principale d'installation
#==============================================================================

main() {
    show_banner
    
    # Vérifications préalables
    check_root
    check_debian_version
    
    # Configuration
    collect_configuration
    
    log "Début de l'installation Fidaous Pro"
    log "Système: $(lsb_release -ds)"
    log "Architecture: $(uname -m)"
    
    # Installation étape par étape
    update_system
    install_lamp_stack
    install_nodejs_composer
    setup_database
    install_fidaous_pro
    install_nextcloud
    configure_apache
    setup_ssl
    configure_security
    setup_cron_jobs
    create_admin_user
    run_tests
    
    # Finalisation
    display_final_info
    
    log "Installation Fidaous Pro terminée avec succès"
}

#==============================================================================
# Gestion des signaux et nettoyage
#==============================================================================

cleanup() {
    log "Nettoyage en cours..."
    rm -f /tmp/nextcloud.zip
    log "Nettoyage terminé"
}

trap cleanup EXIT

#==============================================================================
# Exécution du script principal
#==============================================================================

main "$@"