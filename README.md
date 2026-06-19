# Facturation RH

Prototype Flutter desktop/web pour remplacer progressivement le fichier Excel de facturation.

## Lancer

```powershell
cd C:\Users\hp\Documents\fact\facturation_app
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Pour lancer sur web :

```powershell
flutter run -d chrome
```

## Etat du prototype

- Navigation principale : Facturation, Dashboard, Import, Export, Parametres.
- Page Facturation avec grille editable, filtres, recherche, resume annuel et panneau detail.
- Calculs locaux : montant attendu, total paye, reliquat.
- Simulation de synchronisation : enregistre, en attente, sync, erreur, hors ligne.
- Systeme d'icones premium avec Hugeicons.
- Socle de synchronisation locale : file de modifications, remplacement des edits successifs sur une meme cellule, flush asynchrone.
- Sauvegarde locale automatique des lignes et annees avec SharedPreferences.
- Premier lancement vide si aucune donnee locale n'existe encore.
- Donnees de demonstration conservees pour les tests et prototypes controles.

## Reinitialiser les donnees locales

En mode debug, ouvrir `Parametres`, puis cliquer sur `Reinitialiser les donnees locales`.

Suppression manuelle Windows possible :

```powershell
Remove-Item -Recurse -Force "$env:APPDATA\com.example\facturation_app"
```

Si le dossier n'existe pas, verifier aussi :

```powershell
Get-ChildItem "$env:APPDATA" -Recurse -Directory -Filter "facturation_app" -ErrorAction SilentlyContinue
```

## Prochaine etape technique

- Brancher une vraie grille Flutter specialisee apres prototype comparatif.
- Ajouter persistence locale desktop.
- Ajouter Firebase/Firestore.
- Implementer import/export Excel reels.
