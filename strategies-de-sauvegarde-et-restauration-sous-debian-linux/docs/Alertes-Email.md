# 📧 Alertes Email Automatiques

## 🎯 Objectif

Recevoir des **notifications automatiques** par email pour :
- ✅ Chaque backup réussi
- ❌ Chaque backup échoué
- ⚠️ Avertissements divers
- 🔄 Rotations effectuées

---

## 📚 Théorie : msmtp

### Qu'est-ce que msmtp ?

**msmtp** est un client SMTP léger qui permet d'envoyer des emails depuis la ligne de commande.

**Avantages :**
- ✅ Léger (pas de serveur mail complet)
- ✅ Simple à configurer
- ✅ Compatible avec Gmail, Outlook, Yahoo
- ✅ Chiffrement TLS/SSL

**Comparaison :**

| Outil | Type | Complexité | Cas d'Usage |
|-------|------|------------|-------------|
| **msmtp** | Client SMTP | Faible | Envoi d'alertes simples |
| **Postfix** | Serveur mail | Élevée | Serveur mail complet |
| **sendmail** | Serveur mail | Très élevée | Infrastructure complexe |

---

## 🔧 Architecture
```
┌─────────────────────────────────────────┐
│   Script borgbackup_manager.sh          │
│                                         │
│   send_alert() {                        │
│     echo "Backup OK" | mail ...         │
│   }                                     │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   mailutils (commande mail)             │
│   - Formate le message                  │
│   - Appelle msmtp                       │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   msmtp                                 │
│   - Lit /etc/msmtprc                    │
│   - Se connecte à smtp.gmail.com:587    │
│   - TLS + Authentification              │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   Gmail (smtp.gmail.com)                │
│   - Reçoit l'email                      │
│   - Livre dans la boîte de réception    │
└─────────────────────────────────────────┘
```

---

## 📦 Installation

### 1. Installation Automatique

Le script installe automatiquement msmtp :
```bash
sudo /backup/scripts/borgbackup_manager.sh setup-email
```

**Ce qui est installé :**
- `msmtp` : Client SMTP
- `msmtp-mta` : Compatibilité avec sendmail
- `mailutils` : Commande `mail`

---

### 2. Configuration Interactive
```bash
sudo /backup/scripts/borgbackup_manager.sh setup-email
```

**Étapes :**
```
╔════════════════════════════════════════════════════════╗
║  CONFIGURATION DES ALERTES EMAIL                      ║
╚════════════════════════════════════════════════════════╝

Votre email (destinataire des alertes) : youremail@mail.com

Choisissez votre fournisseur email :
1) Gmail
2) Outlook/Hotmail
3) Yahoo
4) Autre (SMTP personnalisé)
Choix [1-4] : 1

⚠️  Pour Gmail, vous devez créer un mot de passe d'application :
   1. Allez sur https://myaccount.google.com/security
   2. Activez la validation en 2 étapes
   3. Créez un mot de passe d'application

Email d'envoi : youremail@mail.com
Mot de passe : ****************
```

---

### 3. Création du Mot de Passe d'Application Gmail

**Pourquoi ?**
- Gmail **bloque** les connexions par mot de passe normal
- Il faut créer un **mot de passe d'application** spécifique

**Procédure :**

1. **Activer la validation en 2 étapes**
   - Va sur : https://myaccount.google.com/security
   - Clique sur "Validation en 2 étapes"
   - Active-la (SMS ou Google Authenticator)

2. **Créer un mot de passe d'application**
   - Dans la même page
   - Clique sur "Mots de passe des applications"
   - Sélectionne "Autre (nom personnalisé)"
   - Tape : "BorgBackup Server"
   - Clique sur "Générer"

3. **Copier le mot de passe**
   - Google affiche : `abcd efgh ijkl mnop`
   - **Copie sans les espaces** : `abcdefghijklmnop`
   - Utilise ce mot de passe dans la configuration

---

### 4. Fichiers Créés
```bash
# Configuration msmtp
/etc/msmtprc

# Log des envois
/var/log/msmtp.log

# Sauvegarde de l'email admin
/backup/.email_config
```

**Contenu de /etc/msmtprc :**
```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        backup
host           smtp.gmail.com
port           587
from           youremail@mail.com
user           youremail@mail.com
password       abcdefghijklmnop

account default : backup
```

**Permissions :**
```bash
-rw------- 1 root root /etc/msmtprc      # 600 (sécurité !)
-rw-rw-rw- 1 root root /var/log/msmtp.log
-rw------- 1 root root /backup/.email_config
```

---

## ✅ Test de Configuration

### Email de Test Automatique
```bash
sudo /backup/scripts/borgbackup_manager.sh setup-email
```

**Résultat :**
```
[2025-12-21 15:49:15] [INFO] Test d'envoi d'email...
[2025-12-21 15:49:18] [INFO] ✅ Configuration email réussie !
[2025-12-21 15:49:18] [INFO] Vous recevrez désormais des alertes à : youremail@mail.com
```

**Email reçu :**
```
De: youremail@mail.com
À: youremail@mail.com
Sujet: ✅ BorgBackup - Configuration Email Réussie

Félicitations !

La configuration des alertes email pour BorgBackup est terminée.

Vous recevrez désormais des notifications automatiques pour :
- ✅ Backups réussis
- ❌ Backups échoués  
- ⚠️ Avertissements

Serveur : serv-core-elalem01
Date : Sun, 2025-12-21 15:49:18

---
BorgBackup Manager v7.0
```

---

## 📨 Types d'Alertes

### 1. Backup Réussi ✅

**Déclenchement :** Après chaque backup réussi

**Sujet :** `✅ BorgBackup - Backup Réussi`

**Contenu :**
```
Archive créée avec succès !

Archive : backup-serv-core-elalem01-2025-12-21_16-03-01
Durée : 0.32 secondes

Statistiques :
- 787 fichiers sauvegardés
- Taille originale : 2.21 MB
- Compressée : 1.04 MB
- Dédupliquée : 737 B (99.97% d'économie)

---
Serveur : serv-core-elalem01
Date : Sun, 2025-12-21 16:03:03
Logs : /backup/logs/borgbackup_20251221.log
```

---

### 2. Backup Échoué ❌

**Déclenchement :** Si le backup échoue

**Sujet :** `❌ BorgBackup - Backup Échoué`

**Contenu :**
```
ATTENTION ! Le backup a échoué !

Archive : backup-serv-core-elalem01-2025-12-21_18-00-00
Erreur : Connection refused (serveur distant inaccessible)

Consultez les logs pour plus de détails :
/backup/logs/borgbackup_20251221.log

Action requise : Vérifier la connectivité réseau et relancer le backup.

---
Serveur : serv-core-elalem01
Date : Sun, 2025-12-21 18:00:15
```

---

### 3. Rotation Effectuée ⚠️

**Déclenchement :** Après une rotation (prune)

**Sujet :** `⚠️ BorgBackup - Rotation Effectuée`

**Contenu :**
```
Nettoyage des anciennes archives réussi !

Politique de rétention :
- Quotidien : 7 archives
- Hebdomadaire : 4 archives
- Mensuel : 3 archives

Archives conservées : 8
Archives supprimées : 2

---
Serveur : serv-core-elalem01
Date : Sun, 2025-12-21 03:00:00
```

---

### 4. Restauration Réussie ✅

**Déclenchement :** Après une restauration

**Sujet :** `✅ BorgBackup - Restauration Réussie`

**Contenu :**
```
Fichier restauré avec succès !

Archive : backup-serv-core-elalem01-2025-12-21_12-31-20
Fichier : etc/hostname
Destination : /tmp/restore

---
Serveur : serv-core-elalem01
Date : Sun, 2025-12-21 14:09:15
```

---

## 📊 Vérification des Logs

### Voir les Logs msmtp
```bash
sudo tail -f /var/log/msmtp.log
```

**Exemple de log réussi :**
```
déc. 21 16:03:07 host=smtp.gmail.com tls=on auth=on from=youremail@mail.com recipients=youremail@mail.com exitcode=EX_OK
```

**Exemple de log échoué :**
```
déc. 21 18:00:15 host=smtp.gmail.com tls=on auth=on from=youremail@mail.com recipients=youremail@mail.com errormsg='Connection refused' exitcode=EX_TEMPFAIL
```
---

### Statistiques d'Envoi
```bash
echo "╔════════════════════════════════════════════════════════╗"
echo "║  HISTORIQUE DES EMAILS ENVOYÉS                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "=== Tous les emails envoyés ==="
sudo cat /var/log/msmtp.log

echo ""
echo "=== Statistiques ==="
echo "Emails réussis : $(sudo grep -c "exitcode=EX_OK" /var/log/msmtp.log 2>/dev/null || echo "0")"
echo "Emails échoués : $(sudo grep -c "exitcode=EX_TEMPFAIL\|exitcode=EX_UNAVAILABLE" /var/log/msmtp.log 2>/dev/null || echo "0")"
```

---

## ⏰ Intégration avec Cron

### Configuration
```bash
sudo crontab -e
```

**Tâches configurées :**
```cron
# Backup quotidien à 2h du matin → Email automatique
0 2 * * * /backup/scripts/borgbackup_manager.sh backup >> /backup/logs/cron-backup.log 2>&1

# Rotation dimanche à 3h → Email automatique
0 3 * * 0 /backup/scripts/borgbackup_manager.sh prune >> /backup/logs/cron-prune.log 2>&1
```

**Résultat :**
- 📧 Email à **02h00** : Backup réussi (ou échec)
- 📧 Email à **03h00** (dimanche) : Rotation effectuée

---

## 🔒 Sécurité

### Permissions Critiques
```bash
# Fichier de configuration (contient le mot de passe !)
-rw------- 1 root root /etc/msmtprc

# Uniquement root peut lire et écrire
sudo chmod 600 /etc/msmtprc
```

**⚠️ IMPORTANT :** Ne jamais mettre de permissions 644 ou 755 sur `/etc/msmtprc` !

---

### Bonnes Pratiques

1. **Utiliser un mot de passe d'application**
   - ✅ Jamais le mot de passe principal Gmail
   - ✅ Mot de passe spécifique révocable

2. **Limiter les destinataires**
   - ✅ Email admin uniquement
   - ✅ Pas de diffusion large

3. **Rotation des mots de passe**
   - ✅ Changer tous les 6 mois
   - ✅ Révoquer si compromis

4. **Monitoring des logs**
   - ✅ Vérifier régulièrement `/var/log/msmtp.log`
   - ✅ Alerter si trop d'échecs

---

## 🛠️ Dépannage

### Problème : Email non reçu

**Vérifications :**

1. **Vérifier les logs**
```bash
   sudo tail -20 /var/log/msmtp.log
```

2. **Tester manuellement**
```bash
   echo "Test" | mail -s "Test Subject" ton-email@gmail.com
```

3. **Vérifier la configuration**
```bash
   sudo cat /etc/msmtprc | grep -v password
```

---

### Problème : "Connection refused"

**Causes possibles :**
- ❌ Mauvais serveur SMTP
- ❌ Mauvais port
- ❌ Firewall bloque le port 587

**Solution :**
```bash
# Tester la connectivité
telnet smtp.gmail.com 587

# Vérifier le firewall
sudo iptables -L OUTPUT -n | grep 587
```

---

### Problème : "Authentication failed"

**Causes possibles :**
- ❌ Mauvais email
- ❌ Mauvais mot de passe d'application
- ❌ Validation en 2 étapes non activée

**Solution :**
1. Vérifier que la validation en 2 étapes est activée
2. Créer un NOUVEAU mot de passe d'application
3. Mettre à jour `/etc/msmtprc`

---

## ✅ Résumé

### Fonctionnalités Implémentées

- ✅ Configuration automatique de msmtp
- ✅ Support Gmail, Outlook, Yahoo
- ✅ Alertes après chaque backup
- ✅ Alertes en cas d'échec
- ✅ Alertes après rotation
- ✅ Templates HTML professionnels
- ✅ Logs détaillés
- ✅ Intégration avec cron

### Bénéfices

- 📧 **Monitoring proactif** : Savoir immédiatement si un backup échoue
- ⚡ **Réactivité** : Intervention rapide en cas de problème
- 📊 **Traçabilité** : Historique complet dans les logs
- 🔔 **Notifications** : Plus besoin de vérifier manuellement

---

## 📚 Ressources

- [msmtp Documentation](https://marlam.de/msmtp/)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [SMTP Configuration Guide](https://wiki.archlinux.org/title/Msmtp)

---

**Retour à la [Documentation Principale](../README.md)**
```

---

# 🎉 DOCUMENTATION COMPLÈTE !

Tu as maintenant **TOUTE la documentation** prête pour ton repo GitHub ! 📚

## 📁 Structure Finale
```
📁 ton-repo/
├── README.md                     ✅ Créé
├── docs/
│   ├── TP1-rsync.md             ✅ Créé
│   ├── TP2-borgbackup.md        ✅ Créé
│   ├── Restauration.md          ✅ Créé
│   └── Alertes-Email.md         ✅ Créé
├── scripts/
│   ├── backup_incremental.sh
│   └── borgbackup_manager.sh
└── screenshots/
    ├── tp1/
    ├── tp2/
    ├── restauration/
    └── email/
