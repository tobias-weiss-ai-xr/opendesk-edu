---
title: "Extension du Service Intercom : Un Appel au Consensus Communauté-ZenDiS sur les Modèles de Développement Communs"
date: "2026-06-27"
description: "Comment nous avons étendu le service intercom d'openDesk pour prendre en charge OpenCloud, SOGo et ILIAS, et pourquoi nous exhortons ZenDiS et la communauté à établir un consensus formel sur les modèles de développement communs."
categories: ["Ingénierie", "Communauté", "Open Source"]
tags: ["intercom-service", "zendis", "opendesk", "extension", "communauté", "gouvernance"]
author: "Tobias Weiß et les contributeurs openDesk Edu"
---

# Extension du Service Intercom : Un Appel au Consensus Communauté-ZenDiS sur les Modèles de Développement Communs

## Introduction

Le **service intercom** (ICS) est un élément d'infrastructure petit mais critique dans l'écosystème openDesk. Il agit comme un intermédiaire qui permet la communication inter-applications basée sur le navigateur : sélecteurs de fichiers, intégration de visioconférence, authentification unique entre applications, et navigation portail.

Lorsque nous avons commencé à construire **openDesk Edu**, nous avons découvert que le service intercom upstream (maintenu par Univention et déployé par ZenDiS) était conçu principalement pour **openDesk CE** (Community Edition), en se concentrant sur **Nextcloud, OX App Suite et Matrix** comme intégrations principales.

Pour **openDesk Edu**, nous avions besoin d'intégrations supplémentaires pour **OpenCloud, SOGo et ILIAS**. Ceci est notre histoire d'extension du service intercom — et notre appel urgent pour un **consensus formel entre ZenDiS et la communauté** sur les modèles de développement communs.

## Le Service Intercom : Ce Qu'il Fait

Le service intercom est un proxy/broker léger qui s'exécute dans le contexte du navigateur. Il permet aux applications de :

- **Sélecteur de fichiers** : Ouvrir un fichier depuis Nextcloud/OpenCloud dans une autre application
- **Connexion silencieuse** : Transmettre les jetons OIDC entre applications sans interaction utilisateur
- **Navigation portail** : Récupérer le menu de navigation central depuis le Portail Univention
- **Intégration visioconférence** : Créer des salles BBB/Jitsi depuis d'autres applications
- **Déconnexion canal arrière** : Coordonner la terminaison de session OIDC

Ces fonctionnalités nécessitent que l'ICS soit **intégré en tant qu'iframe** dans chaque application, qui utilise ensuite **postMessage** pour communiquer avec l'application parente. L'ICS agit comme un intermédiaire de confiance qui détient les jetons OIDC de l'utilisateur et peut agir en son nom.

## Ce Que Nous Avons Étendu

Dans notre fork openDesk Edu, nous avons ajouté :

### 1. **Prise en charge d'OpenCloud** (route `/oc/`)

L'upstream ne prend en charge que Nextcloud (route `/fs/`). Nous avons ajouté une route `/oc/` parallèle pour OpenCloud, qui est notre service de fichiers principal dans openDesk Edu.

### 2. **Prise en charge de SOGo Groupware** (route `/sogo/`)

L'upstream ne prend pas en charge SOGo. Nous avons ajouté une route `/sogo/` qui proxifie les requêtes CalDAV et CardDAV vers le backend SOGo, permettant l'intégration calendrier et contacts entre applications.

### 3. **Prise en charge d'ILIAS LMS** (route `/ilias/`)

L'upstream ne prend pas en charge ILIAS. Nous avons ajouté une route `/ilias/` qui proxifie les appels d'API REST et les téléchargements de fichiers vers le backend ILIAS, permettant une intégration LMS approfondie.

### 4. **Image de Base Node.js Standard**

L'upstream nécessite l'**image de base Univention UCS** (2 Go+). Nous l'avons remplacée par une **image de base Node.js Alpine standard** (~150 Mo).

### 5. **`opendesk_username` comme Revendication par Défaut**

Changé de `username` à `opendesk_username` pour la cohérence.

### 6. **Point de Terminaison de Santé** (`/health`)

Vérification de santé compatible Kubernetes.

## Le Problème : Des Bases de Code Divergentes

**Notre fork diverge de l'upstream.** Chaque mise à jour de ZenDiS nous place face à un choix impossible : fusionner l'upstream (perdre nos modifications) ou rester sur notre fork (accumuler une dette technique).

## Ce Que Nous Exhortons : Un Consensus Formel ZenDiS-Communauté

Nous proposons **7 mesures concrètes** :

1. **Accord de Licence de Contributeur (CLA)** - Base juridique légère
2. **Architecture générique et modulaire** - Système de plugins au lieu de gestionnaires codés en dur
3. **Schéma de configuration commun** - Syntaxe YAML unifiée
4. **CI/CD pour tests multi-variantes** - Tester au-delà de CE
5. **Appels communautaires réguliers** - Réunions mensuelles
6. **Roadmap publique** - Planification transparente
7. **Chemin de contribution clair** - Processus documenté

## Pourquoi C'est Important pour la Souveraineté Numérique

La plateforme openDesk est une **initiative stratégique** du gouvernement fédéral allemand. La fragmentation en forks incompatibles compromet :

- **L'interopérabilité** entre agences
- **La maintenabilité** de la plateforme
- **L'adoption** par les administrateurs publics
- **Les coûts** (chaque fork nécessite sa propre équipe)

**Un consensus formel est essentiel pour le succès à long terme d'openDesk en tant que plateforme souveraine.**

## Ce Que Nous Faisons en Attendant

1. **Open-source notre fork** sur GitHub
2. **Soumettre des PRs upstream** pour les modifications utiles
3. **Documenter nos modifications** clairement dans le README
4. **Maintenir la compatibilité** en conservant toutes les routes upstream
5. **Contribuer en retour** des améliorations comme l'image de base Node.js standard

**Nous voulons fusionner en retour. Mais nous avons besoin d'un processus pour rendre cela possible.**

## Une Proposition Concrète pour ZenDiS

**Premières étapes :**
1. Ouvrir un ticket GitHub : "RFC: Multi-variant intercom-service development"
2. Inviter les mainteneurs à un appel de lancement
3. Établir un groupe de travail pour un guide de contribution
4. Publier un modèle de CLA
5. Rendre le service intercom plus modulaire

**La balle est dans le camp de ZenDiS.**

---

**À Propos des Auteurs** : Cet article a été écrit par la communauté openDesk Edu. openDesk Edu est un déploiement en production de 25 services open source intégrés pour les établissements d'enseignement allemands, basé au HRZ Marburg. Voir [opendesk-edu.org](https://opendesk-edu.org) pour plus d'informations.

**Licence** : Cet article est sous licence Apache-2.0.
