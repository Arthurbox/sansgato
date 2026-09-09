# Changelog

Tous les changements notables apportés au projet Sansgato seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-08-15
### Ajouté
- Espace Administration (Back-office) directement intégré dans l'application mobile.
- Nouveau workflow (Wizard) pour la création de produits par un administrateur.
- Intégration de la géolocalisation pour définir l'adresse de livraison.

### Modifié
- Refonte de la page détail du produit pour inclure la gestion des commentaires et notes.
- Amélioration des performances de chargement des listes avec des Skeleton Loaders (`shimmer`).

## [1.1.0] - 2026-06-10
### Ajouté
- Authentification par numéro de téléphone (OTP) via l'API Twilio.
- Intégration des moyens de paiement locaux (Wave, Orange Money, Moov).
- Connexion avec les réseaux sociaux (Google et Facebook).

### Modifié
- Migration de l'état de l'application vers `flutter_riverpod`.

## [1.0.0] - 2026-04-01
### Ajouté
- Version initiale de l'application.
- Catalogue de produits avec recherche basique.
- Panier d'achat local (sauvegardé sur l'appareil).
- Connexion utilisateur classique (Email/Mot de passe).
- Backend basique avec Django et SQLite.
