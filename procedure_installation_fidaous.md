# Procédure d'Installation Fidaous Pro
## Guide Opérationnel pour Déploiement sur Debian 12

### Présentation de la Procédure

Cette procédure détaille le processus complet d'installation de l'application Fidaous Pro, une solution de gestion de cabinet comptable spécialement conçue pour répondre aux normes et exigences du marché marocain. L'installation automatisée garantit un déploiement cohérent et sécurisé de tous les composants nécessaires au fonctionnement optimal de l'application.

### Prérequis Techniques

La mise en œuvre de cette installation nécessite un serveur dédié ou virtuel répondant aux spécifications minimales suivantes. Le serveur doit fonctionner sous Debian 12 (Bookworm) avec un accès root complet pour permettre l'installation et la configuration de l'ensemble des services système requis.

Les ressources matérielles minimales comprennent 4 GB de mémoire vive, 50 GB d'espace disque disponible, et un processeur dual-core. Pour un environnement de production gérant plus de 50 clients simultanés, il est recommandé de prévoir 8 GB de RAM et 100 GB d'espace disque. Une connexion Internet stable est indispensable pour le téléchargement des composants et la configuration des certificats SSL.

Le serveur doit également disposer d'un nom de domaine valide configuré avec les enregistrements DNS appropriés. Il est recommandé de configurer à la fois le domaine principal et un sous-domaine pour Nextcloud avant de débuter l'installation.

### Préparation de l'Environnement

La première étape consiste à sécuriser l'accès au serveur et à préparer l'environnement d'installation. Cette phase inclut la configuration de l'accès SSH avec authentification par clés, la mise à jour complète du système, et la désactivation des services non essentiels pour optimiser la sécurité.

Il est crucial de documenter la configuration réseau existante et de s'assurer que les ports nécessaires (80, 443, 22) sont accessibles depuis Internet. La configuration du pare-feu local sera gérée automatiquement par le script d'installation, mais les règles de pare-feu externes doivent être vérifiées au préalable.

La sauvegarde de toute configuration existante sur le serveur constitue une étape de précaution indispensable. Bien que l'installation soit conçue pour fonctionner sur un système propre, cette mesure préventive garantit la possibilité de restaurer l'état antérieur si nécessaire.

### Procédure d'Exécution

Le processus d'installation débute par le téléchargement du script automatisé depuis le référentiel officiel. Cette opération s'effectue en utilisant les commandes wget ou curl pour récupérer la version la plus récente du script d'installation, garantissant ainsi l'accès aux dernières améliorations et correctifs de sécurité.

```bash
wget https://raw.githubusercontent.com/fidaouspro/installation/main/install-debian12.sh
chmod +x install-debian12.sh
```

L'exécution du script nécessite les privilèges administrateur système. Le lancement s'effectue avec la commande sudo, déclenchant immédiatement la phase de vérification des prérequis système et l'affichage de l'interface de configuration interactive.

```bash
sudo ./install-debian12.sh
```

### Phase de Configuration Interactive

Le script présente une interface guidée qui collecte les informations essentielles à la personnalisation de l'installation. Cette phase interactive garantit que chaque déploiement respecte les spécificités organisationnelles du cabinet comptable concerné.

La première information requise concerne le nom de domaine principal qui hébergera l'application. Cette donnée détermine la configuration des certificats SSL et l'accès public à l'application. Le format attendu correspond à un nom de domaine complet, par exemple "cabinet-exemple.ma" ou "fidaous-pro.ma".

L'adresse électronique de l'administrateur principal constitue le second paramètre requis. Cette information sert à la configuration des certificats SSL Let's Encrypt et devient l'identifiant de connexion principal pour l'accès administrateur à l'application.

Le système génère automatiquement l'ensemble des mots de passe nécessaires au fonctionnement des différents services. Cette approche garantit un niveau de sécurité optimal en évitant l'utilisation de mots de passe faibles ou réutilisés. Tous les mots de passe générés sont documentés dans un fichier sécurisé accessible uniquement à l'administrateur système.

### Installation des Composants Système

La phase d'installation système procède méthodiquement à la mise en place de tous les composants logiciels nécessaires. Cette étape commence par la mise à jour complète des paquets système pour garantir l'utilisation des versions les plus récentes et sécurisées de tous les composants.

L'installation de la pile LAMP constitue le fondement technique de l'application. Apache 2.4 est configuré avec les modules nécessaires pour supporter les applications PHP modernes et les certificats SSL. MySQL 8.0 est déployé avec une configuration sécurisée incluant la suppression des comptes par défaut et la définition de mots de passe robustes. PHP 8.2 est installé avec l'ensemble des extensions requises pour le fonctionnement optimal de l'application et l'intégration avec les services externes.

Node.js et Composer complètent l'environnement de développement, permettant la gestion des dépendances JavaScript et PHP. Ces outils garantissent que l'application dispose de toutes les bibliothèques nécessaires dans leurs versions appropriées.

### Configuration de la Base de Données

La création et la configuration de la base de données s'effectuent selon les meilleures pratiques de sécurité. Le script établit automatiquement la base de données principale "database_fidaous_pro" avec l'encodage UTF-8 approprié pour supporter les caractères arabes et français utilisés dans l'environnement marocain.

Un utilisateur dédié "fidaous_user" est créé avec des privilèges strictement limités à la base de données de l'application. Cette approche respecte le principe de moindre privilège, réduisant les risques de sécurité en cas de compromission de l'application.

La structure de base de données est importée automatiquement, créant l'ensemble des tables, index, et contraintes nécessaires au fonctionnement de l'application. Les données initiales, incluant les paramètres système et les rôles utilisateurs, sont également insérées pour permettre un démarrage immédiat de l'application.

### Déploiement de l'Application

L'installation de l'application Fidaous Pro s'effectue dans le répertoire standard "/var/www/html/fidaous-pro", garantissant une organisation cohérente avec les conventions système. L'ensemble de la structure de fichiers est déployée avec les permissions appropriées pour assurer le fonctionnement sécurisé de l'application.

La configuration des Virtual Hosts Apache établit l'accès public à l'application via le domaine configuré. Cette étape inclut la mise en place des règles de réécriture nécessaires au fonctionnement de l'API REST et à la gestion des routes applications.

Les fichiers de configuration sont personnalisés avec les paramètres spécifiques à l'installation, incluant les informations de connexion à la base de données et les clés de sécurité générées automatiquement.

### Installation et Configuration de Nextcloud

Le déploiement de Nextcloud pour la gestion documentaire cloud s'effectue en parallèle de l'application principale. Cette intégration permet aux cabinets comptables de bénéficier immédiatement d'une solution de stockage et de partage documentaire sécurisée.

Nextcloud est installé dans un répertoire dédié avec sa propre base de données pour garantir l'isolation des données. Un Virtual Host spécifique est configuré sur le sous-domaine "cloud" pour permettre l'accès direct à l'interface Nextcloud.

L'intégration entre Fidaous Pro et Nextcloud est préconfigurée avec les paramètres d'authentification et les chemins d'accès appropriés. Cette configuration permet l'upload automatique des documents depuis l'application vers le cloud et la synchronisation bidirectionnelle des fichiers.

### Configuration SSL et Sécurité

La sécurisation des communications constitue une priorité absolue dans le déploiement de l'application. Le script configure automatiquement les certificats SSL via Let's Encrypt pour le domaine principal et le sous-domaine Nextcloud, garantissant le chiffrement de toutes les communications.

Fail2Ban est déployé et configuré pour protéger le serveur contre les tentatives d'intrusion par force brute. Les règles de protection couvrent les services SSH, Apache, et les tentatives d'accès non autorisées aux applications.

Le pare-feu UFW est activé avec une configuration restrictive n'autorisant que les ports strictement nécessaires au fonctionnement des services. Cette approche minimise la surface d'attaque du serveur.

### Automatisation et Maintenance

La configuration des tâches automatisées garantit le bon fonctionnement continu de l'application sans intervention manuelle. Les scripts de maintenance sont programmés via cron pour s'exécuter aux heures optimales, minimisant l'impact sur les performances système.

Les sauvegardes automatiques de la base de données sont planifiées quotidiennement avec rotation des fichiers pour optimiser l'utilisation de l'espace disque. La synchronisation avec Nextcloud s'effectue de manière continue pour assurer la cohérence des données documentaires.

Les rappels automatiques via WhatsApp sont programmés selon les besoins métier du cabinet comptable, permettant une communication proactive avec les clients concernant les échéances et obligations fiscales.

### Vérification et Tests

La phase de vérification valide le bon fonctionnement de tous les composants installés. Cette étape inclut des tests de connectivité aux services, de fonctionnement des applications, et d'accès aux interfaces web.

Le script vérifie automatiquement l'état des services système, la connectivité aux bases de données, l'accessibilité des applications web, et le bon fonctionnement des certificats SSL. Tout problème détecté est signalé avec des instructions spécifiques pour la résolution.

Les tests incluent également la validation de la configuration des tâches automatisées et la vérification des permissions de fichiers pour garantir un environnement sécurisé et fonctionnel.

### Finalisation et Documentation

À l'issue de l'installation, le système génère automatiquement une documentation complète de la configuration déployée. Cette documentation inclut l'ensemble des informations nécessaires à l'administration et à la maintenance de l'application.

Les identifiants de connexion, mots de passe générés, et paramètres de configuration sont consignés dans un fichier sécurisé accessible uniquement à l'administrateur système. Cette documentation constitue une référence essentielle pour les opérations de maintenance futures.

Le script fournit également des recommandations spécifiques pour la finalisation de la configuration, incluant la personnalisation des paramètres métier, la configuration des intégrations externes, et les étapes de formation des utilisateurs.

### Post-Installation et Mise en Service

Une fois l'installation technique terminée, plusieurs étapes de configuration métier doivent être réalisées pour adapter l'application aux besoins spécifiques du cabinet comptable. Ces étapes incluent la personnalisation des paramètres organisationnels, la création des comptes utilisateurs, et la configuration des intégrations WhatsApp Business.

La formation des utilisateurs constitue un élément crucial de la mise en service réussie. L'application dispose d'une interface intuitive, mais une formation appropriée garantit une adoption optimale et l'exploitation complète des fonctionnalités disponibles.

L'établissement de procédures de sauvegarde et de maintenance régulières assure la pérennité de l'installation. Ces procédures doivent inclure la surveillance des performances, la mise à jour régulière des composants, et la révision périodique des paramètres de sécurité.

Cette procédure d'installation garantit un déploiement professionnel et sécurisé de l'application Fidaous Pro, offrant aux cabinets comptables marocains un outil moderne et adapté à leurs besoins opérationnels spécifiques.