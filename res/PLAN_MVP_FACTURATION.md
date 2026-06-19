# Plan MVP - Application de facturation RH

## 1. Vision du produit

L'objectif est de remplacer progressivement le fichier Excel `TEST FACTURATION.xlsx` par une application metier moderne, fluide et fiable.

Le logiciel doit rester proche des habitudes actuelles des utilisateurs RH et Direction Generale, sans devenir un ERP complexe. Il doit toutefois etre un vrai logiciel professionnel : robuste, clair, rapide, utilisable au quotidien, et capable de proteger les donnees importantes.

Positionnement du MVP :

- Application de facturation annuelle par ligne metier.
- Experience proche d'un tableur, mais avec controles, calculs et synchronisation.
- Priorite desktop Flutter.
- Support web prevu, mais secondaire au depart.
- Interface simple a comprendre, sans etre simpliste.
- Saisie fluide dans les lignes, comme dans Excel, Google Sheets, Canva, Trello ou Figma : l'utilisateur travaille d'abord, la sauvegarde suit en arriere-plan.

## 2. Principes produit

Le logiciel doit respecter la logique metier existante au lieu de la transformer brutalement.

Principes importants :

- Ne pas fusionner automatiquement des lignes dont les noms se ressemblent.
- Ne pas forcer une normalisation excessive des donnees.
- Ne securiser que les donnees vraiment importantes.
- Ne pas bloquer inutilement l'utilisateur.
- Donner des alertes claires, mais non agressives.
- Permettre la saisie rapide au clavier.
- Garder une logique annuelle, car l'entreprise cree aujourd'hui un nouveau fichier Excel chaque annee.
- Permettre de revenir sur les annees precedentes pour consulter les paiements et reliquats.
- Conserver une interface professionnelle adaptee a des RH, pas une interface enfantine.

## 3. Analyse du fichier Excel

Le fichier analyse contient une seule feuille : `Feuil1`.

Dimensions observees :

- Zone utilisee : `A1:V541`.
- Environ 539 lignes metier.
- Une ligne finale `TOTAUX`.
- Aucune formule detectee dans le fichier.
- Les colonnes mensuelles de janvier a decembre sont presentes, mais vides dans le fichier de test.

Colonnes principales :

| Colonne Excel | Sens metier |
| --- | --- |
| Ref | Reference comptable unique |
| SITE | Nom libre de la ligne de facturation |
| ACTIVITE | Type d'activite |
| Debut | Date de debut de contrat |
| Fin | Date de fin de contrat |
| Nature du Contrat CDD/CDI | Nature du contrat, optionnelle |
| Eff facture | Nombre d'agents factures au client |
| Eff paye | Nombre d'agents payes par la societe |
| Position client | Statut de la ligne/client |
| Janvier a Decembre | Paiements mensuels recus |
| Total | Total annuel |

Constats importants :

- La reference comptable est presque vide dans le fichier de test, mais elle est obligatoire en production.
- Le champ `SITE` est un champ libre. Il represente une ligne de facturation, pas forcement un site physique.
- Une meme valeur de `SITE` peut apparaitre plusieurs fois.
- Une meme valeur de `SITE` peut exister avec plusieurs activites.
- Certaines lignes ont le meme `SITE` et la meme `ACTIVITE`; cela ne doit pas etre considere automatiquement comme une erreur.
- Les dates de fin peuvent etre renseignees en masse si plusieurs contrats s'arretent a la meme periode.
- Le champ `Nature du Contrat` est vide dans le fichier de test et doit rester optionnel.
- `Eff paye` peut etre superieur a `Eff facture`; ce n'est pas une erreur.
- `Eff facture = 0` peut indiquer une ligne incomplete ou une situation connue des utilisateurs; ce ne doit pas etre bloquant.
- Les statuts ne sont pas renseignes dans le fichier de test; les lignes importees doivent etre initialisees a `Actif`.

## 4. Regles metier validees

### 4.1 Reference comptable

La reference comptable est obligatoire en production.

Regles :

- Elle est unique.
- Elle est l'identifiant metier principal.
- Elle doit etre renseignee avant validation definitive d'une ligne.
- Le logiciel doit empecher deux lignes d'avoir la meme reference.

### 4.2 Nom / Site

Le nom est libre.

Regles :

- Le logiciel ne fusionne jamais automatiquement deux noms proches.
- Le nom peut representer un site, un client, une prestation, ou une ligne de facturation.
- Deux lignes peuvent avoir des noms proches ou identiques si la facturation est differente.

### 4.3 Activite

Les activites sont connues et controlees :

- GARDIENNAGE
- NETTOYAGE
- INTERIM
- AUTRE
- LOCATION
- CAMERA
- ADMINISTRATION
- RECRUTEMENT

Le champ doit etre propose sous forme de liste, pour eviter les fautes de saisie, mais sans rendre l'interface lourde.

### 4.4 Contrat

Les dates sont renseignees par l'utilisateur.

Regles :

- Date de debut libre.
- Date de fin libre.
- Date de fin vide si le contrat est encore actif.
- Le logiciel ne doit pas interpreter trop fortement les dates.
- Une date de fin renseignee peut simplement refleter une realite metier connue des utilisateurs.

### 4.5 Effectifs

`Eff facture` represente le nombre d'agents factures au client.

`Eff paye` represente le nombre d'agents effectivement payes par la societe.

Regles :

- `Eff paye` peut etre superieur a `Eff facture`.
- `Eff paye` peut etre inferieur a `Eff facture`.
- `Eff facture = 0` n'est pas bloquant.
- Les ecarts peuvent etre signales discretement, mais pas consideres comme des erreurs.

### 4.6 Tarif mensuel

Le tarif mensuel est libre.

Regles :

- Il est saisi par ligne et par annee.
- Il peut changer d'une annee a l'autre.
- Le logiciel calcule automatiquement le montant attendu.

Calcul :

```text
Montant attendu mensuel = Eff facture x Tarif mensuel
Montant attendu annuel = Montant attendu mensuel x 12
```

### 4.7 Paiements mensuels

Chaque annee contient les paiements de janvier a decembre.

Regles :

- Les paiements sont saisis librement.
- Les cellules mensuelles doivent etre rapides a modifier.
- Les totaux se recalculent immediatement.

### 4.8 Reliquat

Le reliquat est calcule par annee.

Calcul de suivi a date :

```text
Mois dus = janvier -> dernier mois entierement cloture si l'annee selectionnee est l'annee en cours
Mois dus = 12 mois si l'annee selectionnee est une annee passee
Mois dus = 0 mois si l'annee selectionnee est future
```

Exemple :

```text
Date courante : 19 juin
Montant attendu mensuel : 100 000
Paiement recu : 0
Mois pris en compte : janvier a mai
Reliquat = 500 000
```

Le reliquat de suivi ne doit donc pas utiliser automatiquement les 12 mois de l'annee en cours, ni inclure le mois courant tant qu'il n'est pas termine.

Calcul annuel complet, affiche uniquement comme information secondaire :

```text
Reliquat annuel = Montant attendu annuel - Total paye annuel
```

Pour le suivi courant :

```text
Reliquat au mois M = Somme attendue de janvier a M - Somme payee de janvier a M
```

Le logiciel doit aussi permettre de consulter les reliquats des annees precedentes.

### 4.9 Statut

Statuts prevus :

- Actif
- Desactive
- Autre

Regles :

- Les lignes importees sont `Actif` par defaut.
- Si le statut est `Autre`, un commentaire devient obligatoire.
- Dans le MVP, il n'y a pas de suppression definitive.
- La suppression pourra etre ajoutee plus tard si le client le demande.

## 5. Modele metier

Entite centrale : `LigneFacturation`.

Une ligne de facturation correspond a une ligne Excel. Ce n'est pas forcement un client unique, ni un site physique unique.

### 5.1 LigneFacturation

Champs :

- reference
- nom
- activite
- contratDebut
- contratFin
- natureContrat
- effectifFacture
- effectifPaye
- statut
- statutCommentaire
- createdAt
- updatedAt

### 5.2 AnneeFacturation

Une ligne de facturation possede des donnees par annee.

Champs :

- annee
- tarifMensuel
- paiementsMensuels
- montantAttenduMensuel
- montantAttenduAnnuel
- totalPaye
- reliquatAnnuel
- updatedAt

Paiements mensuels :

- janvier
- fevrier
- mars
- avril
- mai
- juin
- juillet
- aout
- septembre
- octobre
- novembre
- decembre

## 6. Modele Firestore propose

Structure recommandee :

```text
facturationLines/{reference}
  reference
  nom
  activite
  contratDebut
  contratFin
  natureContrat
  effectifFacture
  effectifPaye
  statut
  statutCommentaire
  searchText
  createdAt
  updatedAt

facturationLines/{reference}/annees/{annee}
  annee
  tarifMensuel
  paiements
    janvier
    fevrier
    mars
    avril
    mai
    juin
    juillet
    aout
    septembre
    octobre
    novembre
    decembre
  montantAttenduMensuel
  montantAttenduAnnuel
  totalPaye
  reliquatAnnuel
  updatedAt
```

Raisons :

- La reference peut servir d'identifiant documentaire.
- Les donnees generales de la ligne restent stables.
- Les donnees financieres sont separees par annee.
- Les anciennes annees restent consultables.
- Le changement de tarif d'une annee ne casse pas les annees precedentes.
- Les requetes par annee restent propres et maintenables.

## 7. Strategie offline et synchronisation

L'application doit etre pensee comme un logiciel local-first.

Objectif :

- L'utilisateur tape sans attendre le reseau.
- Les calculs s'affichent immediatement.
- Les modifications sont sauvegardees localement.
- La synchronisation avec Firebase se fait en arriere-plan.
- En cas de perte de connexion, l'utilisateur est informe sans etre bloque.
- Apres fermeture et reouverture de l'application, les edits non synchronises ne doivent pas etre perdus.

Architecture cible :

```text
UI Grid
  -> Etat local immediat
  -> Draft buffer
  -> Base locale desktop
  -> Outbox de synchronisation
  -> Sync engine
  -> Firestore
```

Comportement attendu :

- Edition immediate dans la grille.
- Debounce des sauvegardes pour eviter une ecriture par frappe.
- Groupement des modifications par ligne.
- File locale des modifications en attente.
- Indicateur discret : `Enregistre`, `Synchronisation`, `Hors ligne`, `Modifications en attente`.
- Sync automatique au retour de la connexion.
- Pas de popup intrusive a chaque erreur reseau.

Pour desktop, il ne faut pas dependre uniquement du cache Firestore. Une base locale explicite est recommandee.

Options possibles :

- Drift
- Isar

Le choix final devra tenir compte de la stabilite desktop, des besoins de requetes locales, et de la simplicite de maintenance.

## 8. Architecture Flutter proposee

Architecture recommandee :

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart

  core/
    constants/
    errors/
    network/
    sync/
    utils/

  shared/
    widgets/
    layout/
    formatters/

  features/
    facturation/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        controllers/

    dashboard/
      data/
      domain/
      presentation/

    import_export/
      data/
      domain/
      presentation/

    settings/
      presentation/
```

Gestion d'etat recommandee :

- Riverpod pour les providers, controllers, et etats applicatifs.
- Repository pattern pour separer Flutter de Firebase/local DB.
- Use cases pour les actions importantes : sauvegarder une ligne, synchroniser, importer Excel, exporter Excel.

## 9. Direction UI/UX

Le design doit etre professionnel, dense, lisible et rapide.

Il ne faut pas faire :

- Une landing page.
- Une interface marketing.
- Des grands blocs decoratifs inutiles.
- Une application trop coloree ou trop enfantine.
- Une succession de formulaires lents.
- Un ERP avec trop de menus.

Il faut faire :

- Une vraie interface metier.
- Une grille principale performante.
- Des filtres rapides.
- Des actions visibles et previsibles.
- Une navigation simple.
- Des retours d'etat discrets.
- Une experience clavier solide.
- Une lecture claire des montants, statuts et reliquats.

### 9.1 Structure generale de l'application

Disposition cible desktop :

```text
---------------------------------------------------------
| Barre superieure : annee, recherche, sync, utilisateur |
---------------------------------------------------------
| Menu lateral compact | Contenu principal               |
|                      |                                 |
| - Facturation       | Tableau lignes                   |
| - Dashboard         | Detail / panneau lateral         |
| - Export            |                                 |
| - Parametres        |                                 |
---------------------------------------------------------
```

Le premier ecran apres ouverture doit etre directement le tableau de facturation.

### 9.1.1 Style visuel general

Le style doit etre celui d'un logiciel de gestion moderne :

- Dense mais respirant.
- Professionnel mais pas froid.
- Peu decoratif.
- Lisible sur de longues sessions.
- Optimise pour les tableaux, chiffres et statuts.

Direction visuelle :

- Fond general gris tres clair.
- Surfaces principales blanches.
- Bordures fines.
- Rayon de bordure faible, environ 6 a 8 px.
- Typographie simple et nette.
- Contrastes suffisants pour les utilisateurs qui passent beaucoup de temps devant l'ecran.
- Couleurs utilisees pour informer, pas pour decorer.

Palette indicative :

| Usage | Couleur indicative |
| --- | --- |
| Texte principal | Gris tres fonce |
| Texte secondaire | Gris moyen |
| Fond app | Gris tres clair |
| Surface grille | Blanc |
| Bordures | Gris clair |
| Accent principal | Bleu professionnel ou vert sobre |
| Succes sync | Vert discret |
| Attention | Ambre discret |
| Erreur | Rouge modere |
| Ligne desactivee | Gris leger |

Le design ne doit pas etre domine par une seule couleur. Les couleurs doivent aider a lire l'information : activite, statut, reliquat, sync, erreur.

### 9.1.2 Composants UI de base

Composants a prevoir :

- Barre superieure.
- Navigation laterale compacte.
- Grille editable.
- Barre de filtres.
- Chips de filtres actifs.
- Selecteurs compacts.
- Champs de recherche.
- Boutons avec icones.
- Panneau lateral.
- Modales.
- Toasts discrets.
- Barre d'etat basse.
- Badges de statut.
- Indicateurs de sync.
- Menus contextuels sur ligne/cellule.

Regles :

- Les actions frequentes doivent etre visibles.
- Les actions secondaires peuvent etre dans un menu.
- Les boutons doivent avoir des icones quand l'action est claire : ajouter, importer, exporter, filtrer, actualiser.
- Le systeme d'icones principal doit utiliser des icones SVG propres et coherentes, adaptees au desktop.
- Hugeicons est retenu comme piste prioritaire pour le MVP : icones stroke-rounded, rendu SVG, compatible Windows et web.
- Les icones Material par defaut ne doivent pas etre utilisees comme style principal, sauf fallback technique temporaire.
- Les libelles doivent rester simples : `Ajouter`, `Importer`, `Exporter`, `Synchronisation`.
- Les messages doivent etre humains et courts.

### 9.1.3 Densite et lisibilite

La page Facturation doit afficher beaucoup d'information sans devenir fatigante.

Regles :

- Hauteur de ligne stable : environ 40 a 44 px.
- En-tetes de colonnes fixes.
- Colonnes importantes figees.
- Texte tronque avec tooltip si trop long.
- Montants alignes a droite.
- Dates centrees ou alignees de facon constante.
- Statuts en badges sobres.
- Reliquat visible avec couleur ou graisse, mais sans gros effet visuel.
- Pas de cartes decoratives autour de la grille.

Le dashboard peut utiliser des blocs KPI, mais la page Facturation doit rester une surface de travail.

### 9.2 Nombre de pages du MVP

Le MVP doit rester court en navigation. L'application ne doit pas avoir beaucoup de pages, parce que le travail principal se fait dans une grille annuelle.

Nombre recommande :

- 5 pages principales.
- 1 page technique de connexion si authentification activee.
- Plusieurs panneaux/modales, mais pas des pages separees.

Pages principales :

| Page | Role | Priorite |
| --- | --- | --- |
| Connexion | Identifier l'utilisateur | Obligatoire si comptes utilisateurs |
| Facturation | Travailler dans la grille annuelle | Critique |
| Dashboard | Voir les chiffres cles et reliquats | Important |
| Import Excel | Importer le fichier de depart ou une nouvelle annee | Important |
| Export Excel | Sortir un fichier Excel propre | Important |
| Parametres | Gerer activites, statuts, annee par defaut | Secondaire |

Donc, selon le comptage :

- Sans compter la connexion : 5 pages metier.
- Avec connexion : 6 pages visibles.

Ce qui ne doit pas devenir une page :

- Detail d'une ligne : panneau lateral.
- Ajout d'une ligne : ligne inline ou petit panneau.
- Edition des paiements : directement dans la grille.
- Resolution de conflit : modale ou panneau ponctuel.
- Etat de synchronisation : barre basse et panneau detail si probleme.
- Filtres avances : panneau compact au-dessus de la grille.

Regle de choix entre inline, panneau lateral et modale :

| Interaction | Format recommande | Raison |
| --- | --- | --- |
| Modifier une cellule simple | Inline dans la grille | C'est le geste principal, il doit etre instantane |
| Ajouter une ligne simple | Inline ou panneau lateral compact | L'utilisateur doit garder le contexte du tableau |
| Consulter/modifier une ligne complete | Panneau lateral | Assez riche pour structurer les champs, sans quitter la grille |
| Modifier un commentaire statut | Panneau lateral ou petite modale | Le texte peut demander plus d'espace |
| Filtres courants | Barre de filtres | Usage frequent, doit rester visible |
| Filtres avances | Panneau compact | Plus rare, mais utile sans changer de page |
| Import Excel | Page dediee ou grande modale | Flux long, avec verification avant validation |
| Export Excel | Page dediee ou modale moyenne | Flux ponctuel, options a confirmer |
| Resolution de conflit sync | Modale | L'utilisateur doit prendre une decision explicite |
| Erreur critique de sync | Modale seulement si action obligatoire | Eviter de bloquer pour un simple probleme reseau |
| Confirmation destructive future | Modale | Action rare et importante |

Principe :

- Petit changement rapide : inline.
- Consultation ou modification detaillee : panneau lateral.
- Flux long, sensible ou potentiellement perturbant : modale ou page dediee.
- La grille ne doit jamais etre cachee pour une action simple.
- La grille peut etre temporairement couverte si l'action demande toute l'attention de l'utilisateur.

Raison :

- Les utilisateurs RH doivent retrouver vite leur espace de travail.
- Chaque page en plus ajoute une decision et ralentit l'usage quotidien.
- Une application professionnelle n'a pas besoin de beaucoup d'ecrans; elle a besoin d'ecrans bien composes.
- La page Facturation doit concentrer 70 a 80 pourcent de la valeur du MVP.

Navigation cible :

```text
Connexion
  -> Facturation
       -> Panneau detail ligne
       -> Panneau filtres
       -> Modale conflit sync
  -> Dashboard
  -> Import Excel
  -> Export Excel
  -> Parametres
```

La navigation laterale desktop doit rester compacte :

```text
Facturation
Dashboard
Import
Export
Parametres
```

Sur desktop, `Facturation` est la page par defaut apres connexion.

### 9.3 Page Facturation

Role :

- Ecran principal du logiciel.
- Remplacement direct du fichier Excel.
- Consultation, filtre, saisie et correction des lignes.
- Ecran de travail quotidien des RH.
- Page prioritaire du MVP : si cette page est lente ou confuse, le logiciel echoue.

Elements :

- Barre de filtres : annee, activite, statut.
- Recherche globale : reference, nom, activite.
- Bouton d'ajout de ligne.
- Grille principale.
- Panneau de detail optionnel a droite.
- Barre d'etat de synchronisation.
- Resume rapide des totaux de l'annee.

### 9.3.1 Recherche UI/UX et decisions

La page Facturation doit etre pensee comme une grille metier professionnelle, pas comme une simple liste.

Points issus de la recherche et de l'analyse :

- Le composant `DataTable` standard de Flutter n'est pas adapte comme base principale pour une grande grille fluide. La documentation Flutter indique que `DataTable` mesure les colonnes deux fois et que `SingleChildScrollView` monte tout le contenu meme si seulement une partie est visible. Pour de grands volumes, Flutter recommande plutot `TableView` du package `two_dimensional_scrollables`.
- Pour une experience proche Excel, il faut une grille avec virtualisation, edition inline, navigation clavier, colonnes figees, selection de cellules et support du copier/coller.
- Les options a comparer serieusement sont :
  - `Syncfusion Flutter DataGrid` : solution mature, riche, adaptee aux tableaux professionnels.
  - `PlutoGrid` : grille orientee edition, navigation clavier et usage type back-office.
  - `TableView` / `two_dimensional_scrollables` : option plus basse niveau, interessante si on veut maitriser fortement le rendu, mais demandera plus de developpement.
- La decision finale de grille doit etre prise apres un prototype court avec 500 a 2 000 lignes et toutes les colonnes de facturation.

Decision provisoire :

- Ne pas construire la grille principale avec `DataTable`.
- Prototyper en priorite `Syncfusion Flutter DataGrid` et `PlutoGrid`.
- Retenir la solution qui offre la meilleure fluidite desktop, la meilleure edition clavier, et le comportement le plus proche d'Excel.

### 9.3.2 Maquette fonctionnelle desktop

Disposition cible :

```text
------------------------------------------------------------------------------------------------
| Top bar                                                                                        |
| Logo/Nom app | Annee 2026 | Recherche...                         | Sync: Enregistre | Profil |
------------------------------------------------------------------------------------------------
| Nav compacte | Filtres rapides + actions                                                         |
|              | Activite: Toutes | Statut: Actif | Reliquat: Tous | + Ligne | Import | Export |
|--------------|---------------------------------------------------------------------------------|
|              | Resume annee                                                                    |
|              | Lignes: 539 | Eff facture: 1437 | Eff paye: 1753 | Attendu | Paye | Reliquat |
|--------------|---------------------------------------------------------------------------------|
|              | Grille principale                                                                |
|              |---------------------------------------------------------------------------------|
|              | Ref | Nom/Site | Activite | Eff fact | Eff paye | Tarif | Jan | ... | Dec | Reliquat |
|              |---------------------------------------------------------------------------------|
|              | ... lignes editables ...                                                         |
|--------------|---------------------------------------------------------------------------------|
|              | Barre basse : 3 modifications en attente | Derniere sync | Hors ligne si besoin |
------------------------------------------------------------------------------------------------
```

Le panneau detail peut s'ouvrir a droite sans quitter la grille :

```text
------------------------------------------------------------------------------------------------
| Grille principale                                                      | Detail ligne          |
|                                                                        | Reference             |
|                                                                        | Nom                   |
|                                                                        | Activite              |
|                                                                        | Contrat               |
|                                                                        | Statut                |
|                                                                        | Commentaire           |
|                                                                        | Resume paiements      |
------------------------------------------------------------------------------------------------
```

### 9.3.3 Zones de la page

#### Top bar

Role :

- Donner le contexte global.
- Permettre de changer d'annee rapidement.
- Afficher l'etat de synchronisation.

Contenu :

- Nom du logiciel.
- Selecteur d'annee.
- Recherche globale.
- Etat de sync.
- Utilisateur connecte.

Regles :

- L'annee doit etre toujours visible.
- La recherche doit etre accessible au clavier.
- L'etat de sync doit etre discret mais clair.

#### Filtres rapides

Role :

- Reduire rapidement la grille sans ouvrir une page de recherche avancee.

Filtres MVP :

- Activite.
- Statut.
- Reliquat : tous, avec reliquat, sans reliquat.
- Lignes incompletes.

Regles :

- Les filtres doivent etre visibles sous forme de controles compacts.
- Le bouton de remise a zero doit etre disponible.
- Les filtres ne doivent pas recharger toute l'application.

#### Resume annuel

Role :

- Donner les chiffres essentiels de l'annee affichee.

Indicateurs :

- Nombre de lignes.
- Total effectif facture.
- Total effectif paye.
- Montant attendu.
- Total paye.
- Reliquat.

Regles :

- Le resume doit etre compact.
- Il ne doit pas prendre la place de la grille.
- Les valeurs doivent se recalculer immediatement apres edition locale.

#### Grille principale

Role :

- Zone de travail principale.
- Saisie et consultation rapide.

Regles :

- Colonnes `Reference`, `Nom/Site` et `Activite` figees a gauche.
- Colonnes numeriques alignees a droite.
- Mois regroupes visuellement de janvier a decembre.
- Total et reliquat proches des mois.
- Statut visible mais pas dominant.
- Hauteur de ligne stable.
- Pas de changement de taille brutal pendant l'edition.

#### Barre basse

Role :

- Informer sans interrompre.

Etats possibles :

- `Enregistre`
- `Synchronisation...`
- `Hors ligne - modifications conservees sur cet ordinateur`
- `3 modifications en attente`
- `Erreur de sync - action requise`

Regles :

- Pas de popup automatique pour un simple passage hors ligne.
- Une erreur persistante doit pouvoir etre ouverte pour comprendre quoi faire.

### 9.3.4 Colonnes de la grille

Colonnes principales :

- Reference
- Nom
- Activite
- Debut
- Fin
- Nature
- Eff facture
- Eff paye
- Tarif mensuel
- Janvier a Decembre
- Total paye
- Reliquat
- Statut

Organisation recommandee :

```text
Identite       | Contrat        | Effectifs       | Facturation annuelle                    | Suivi
---------------|----------------|-----------------|------------------------------------------|----------------
Ref Nom Act.   | Debut Fin Nat. | Facture Paye    | Tarif Jan Fev Mar ... Dec Total Paye     | Reliquat Statut
```

Largeurs indicatives desktop :

| Colonne | Largeur | Edition |
| --- | ---: | --- |
| Reference | 130 px | Texte obligatoire |
| Nom/Site | 260 px | Texte libre |
| Activite | 150 px | Liste |
| Debut | 110 px | Date |
| Fin | 110 px | Date optionnelle |
| Nature | 120 px | Texte/liste optionnelle |
| Eff facture | 95 px | Nombre |
| Eff paye | 95 px | Nombre |
| Tarif mensuel | 130 px | Montant |
| Janvier a Decembre | 105 px chacun | Montant |
| Total paye | 130 px | Calcule |
| Reliquat | 130 px | Calcule |
| Statut | 120 px | Liste |

Les colonnes calculees ne doivent pas etre editables directement.

Comportements essentiels :

- Edition inline.
- Navigation clavier.
- Copier/coller depuis Excel si possible.
- Colonnes importantes figees.
- Scroll fluide.
- Sauvegarde en arriere-plan.
- Indicateur de ligne modifiee/non synchronisee.

### 9.3.5 Comportement d'edition

Objectif :

- L'utilisateur doit pouvoir taper vite, ligne par ligne, sans attendre la sauvegarde cloud.

Regles :

- Un clic selectionne la cellule.
- Un double clic ou une touche clavier entre en edition.
- `Enter` valide et passe a la ligne suivante.
- `Tab` passe a la cellule suivante.
- `Shift + Tab` revient a la cellule precedente.
- `Esc` annule l'edition en cours.
- Les fleches naviguent entre cellules.
- Le collage depuis Excel doit etre accepte sur une plage compatible.
- Les montants doivent accepter les espaces de milliers si possible.
- Les cellules invalides sont signalees localement, mais sans bloquer toute la ligne sauf reference manquante/doublon lors de validation.

Sauvegarde :

- La modification est appliquee immediatement dans l'etat local.
- Les calculs sont refaits immediatement.
- La sauvegarde est debouncee.
- La ligne passe en etat `modifiee`.
- La sync pousse les changements en arriere-plan.
- Quand Firestore confirme, la ligne repasse en etat `synchronisee`.

### 9.3.6 Etats visuels des lignes et cellules

Etats de ligne :

- Normale.
- Modifiee localement.
- En synchronisation.
- Erreur de synchronisation.
- Incomplete.
- Desactivee.

Etats de cellule :

- Editable.
- Calculee.
- Obligatoire manquante.
- Valeur incoherente mais acceptee.
- Cellule active.
- Cellule en edition.

Regles visuelles :

- Les couleurs doivent rester sobres.
- Les erreurs bloquantes doivent etre visibles.
- Les alertes non bloquantes doivent etre discretes.
- Le reliquat positif doit ressortir, mais sans agresser visuellement.
- Les lignes desactivees peuvent etre grisees.

Palette indicative :

- Fond principal : blanc casse tres leger ou gris tres clair.
- Texte principal : gris tres fonce.
- Accent principal : bleu professionnel ou vert sobre.
- Attention : ambre/orange discret.
- Erreur : rouge modere.
- Succes/sync : vert discret.

### 9.3.7 Experience hors ligne

Quand l'application perd la connexion :

- La grille reste editable.
- Un message discret apparait dans la barre basse.
- Les modifications sont conservees localement.
- L'utilisateur peut continuer son travail.
- La fermeture de l'application ne doit pas faire perdre les modifications.

Texte recommande :

```text
Hors ligne - vos modifications sont conservees sur cet ordinateur et seront synchronisees au retour de la connexion.
```

Quand la connexion revient :

- La sync reprend automatiquement.
- La barre d'etat indique `Synchronisation...`.
- Puis `Enregistre` quand tout est confirme.

### 9.3.8 Gestion des conflits

Le MVP doit eviter les conflits par conception :

- Une meme ligne peut etre modifiee localement puis synchronisee.
- Chaque modification porte un `updatedAt`, un `updatedBy`, et une version locale.
- Si une ligne a ete modifiee ailleurs avant la sync, le logiciel detecte le conflit.

Comportement MVP recommande :

- Pour les champs simples, utiliser la derniere modification confirmee si aucun conflit sensible.
- Pour les paiements mensuels, detecter les conflits cellule par cellule.
- Afficher un panneau de resolution uniquement si deux utilisateurs ont modifie la meme cellule.

Le but est de ne pas surcharger le MVP, mais de ne pas perdre silencieusement les donnees.

### 9.3.9 Ajout de ligne

L'ajout doit etre rapide.

Option recommandee :

- Bouton `+ Ligne`.
- Ajout d'une nouvelle ligne en haut ou en bas de la grille.
- Focus direct dans `Reference`.
- Statut par defaut : `Actif`.
- Annee active creee automatiquement.

Champs minimum pour une ligne exploitable :

- Reference.
- Nom.
- Activite.

Les autres champs peuvent etre completes progressivement.

### 9.3.10 Import depuis Excel

L'import initial doit etre rassurant.

Parcours :

- Selection du fichier Excel.
- Apercu des colonnes detectees.
- Mapping automatique selon le modele existant.
- Liste des lignes avec reference manquante.
- Import possible en brouillon si les references ne sont pas encore disponibles.
- Validation definitive seulement quand les references obligatoires sont renseignees.

Ce point est important car le fichier de test n'a pas les references, alors que la production les aura.

### 9.3.11 Export Excel

L'export doit produire un fichier proche de leurs habitudes.

Regles :

- Une feuille par annee exportee, ou une feuille unique pour l'annee selectionnee.
- Colonnes dans un ordre proche du fichier actuel.
- Janvier a decembre visibles.
- Total et reliquat ajoutes.
- Filtres Excel actifs si possible.
- Format numerique lisible.

L'export est une fonction de confiance : il permet aux utilisateurs de sentir qu'ils ne sont pas enfermes dans le logiciel.

### 9.4 Panneau detail ligne

Role :

- Modifier calmement une ligne sans quitter le tableau.
- Afficher les champs qui prennent trop de place dans la grille.

Contenu :

- Informations generales.
- Contrat.
- Effectifs.
- Statut et commentaire.
- Resume annuel.
- Historique de synchronisation minimal si utile.

Le panneau ne doit pas remplacer la grille. Il doit la completer.

### 9.5 Page Dashboard

Role :

- Donner une vision rapide de l'annee selectionnee.

Indicateurs :

- Nombre total de lignes actives.
- Total effectif facture.
- Total effectif paye.
- Montant attendu annuel.
- Total paye annuel.
- Reliquat total.
- Reliquats par activite.
- Top lignes avec plus gros reliquats.

Design :

- Dense et lisible.
- Peu de graphiques au MVP.
- Priorite aux chiffres utiles.

### 9.6 Page Export

Role :

- Exporter les donnees au format Excel.

Fonctions :

- Choisir l'annee.
- Choisir les filtres a exporter.
- Exporter dans un format proche du fichier actuel.

### 9.7 Page Import Excel

Role :

- Importer le fichier Excel initial.
- Importer eventuellement un fichier d'une nouvelle annee.
- Rassurer les utilisateurs en montrant ce qui sera cree avant validation.

Fonctions :

- Selection du fichier.
- Apercu des feuilles et colonnes detectees.
- Mapping automatique.
- Signalement des references manquantes.
- Creation en brouillon si necessaire.
- Rapport d'import.

Cette page ne doit pas etre utilisee au quotidien. Elle sert surtout au demarrage et aux operations exceptionnelles.

### 9.8 Page Parametres

Role :

- Gérer les listes simples et preferences.

Elements MVP :

- Liste des activites.
- Statuts.
- Annee active par defaut.
- Parametres d'export.

## 10. Points UI/UX a approfondir ensuite

Ces points seront ajoutes au plan apres decision :

- Prototype comparatif de grille Flutter : PlutoGrid vs Syncfusion DataGrid.
- Test de performance avec 500, 2 000 puis 10 000 lignes simulees.
- Validation du copier/coller Excel.
- Validation de la navigation clavier.
- Maquette basse fidelite visuelle de la page Facturation.
- Maquette desktop haute fidelite.
- Adaptation web.
- Regles de couleurs pour statuts et reliquats.
- Comportement exact de la sauvegarde automatique.
- Gestion des conflits de synchronisation.
- Experience d'import du fichier Excel initial.
- Experience d'export Excel final.
- Tests utilisateurs simples avec une personne RH.

## 11. MVP fonctionnel

Fonctionnalites du MVP :

- Consulter les lignes.
- Rechercher.
- Filtrer par annee, activite, statut.
- Ajouter une ligne.
- Modifier une ligne.
- Saisir les paiements mensuels.
- Calculer les montants attendus.
- Calculer les totaux payes.
- Calculer les reliquats.
- Suivre les annees precedentes.
- Exporter en Excel.
- Travailler hors ligne avec synchronisation ulterieure.

Hors MVP :

- Suppression definitive.
- Gestion complete des clients.
- Gestion RH des agents.
- Paie.
- Comptabilite complete.
- Workflow de validation complexe.
- ERP complet.

## 12. Etat d'avancement du prototype Flutter

Date de mise a jour : 19 juin 2026.

Cette section suit ce qui a deja ete construit dans le projet Flutter `facturation_app`, ce qui est en cours, et ce qui reste a faire pour arriver a un MVP utilisable en conditions reelles.

### 12.1 Realise

#### Projet et base technique

- Projet Flutter cree avec support Windows et web.
- Priorite desktop respectee : l'application se lance sur Windows.
- Theme applicatif mis en place : interface claire, dense, professionnelle, adaptee a un logiciel de gestion.
- Navigation principale creee avec les pages :
  - Facturation
  - Dashboard
  - Import
  - Export
  - Parametres
- Systeme d'icones remplace par Hugeicons pour un rendu plus propre et plus adapte au desktop.
- Tests et analyse Flutter deja passes avec succes avant la derniere brique d'import :
  - `flutter analyze` : aucun probleme.
  - `flutter test` : 6 tests passes.

#### Modele metier

- Modele `BillingLine` cree pour representer une ligne de facturation.
- Modele `AnnualBillingData` cree pour separer les donnees par annee.
- Liste controlee des activites integree :
  - GARDIENNAGE
  - NETTOYAGE
  - INTERIM
  - AUTRE
  - LOCATION
  - CAMERA
  - ADMINISTRATION
  - RECRUTEMENT
- Statuts integres :
  - Actif
  - Desactive
  - Autre
- Statut initial des lignes creees ou importees : `Actif`.
- Reference obligatoire signalee visuellement, sans bloquer la saisie rapide.
- Detection des references en doublon dans la grille.
- Detection des lignes incompletes.

#### Page Facturation

- Page principale construite autour d'une grille editable.
- Grille avec colonnes principales :
  - Reference
  - Nom / Site
  - Activite
  - Debut
  - Fin
  - Nature
  - Eff facture
  - Eff paye
  - Tarif mensuel
  - Janvier a decembre
  - Total paye
  - Reliquat
  - Statut
  - Sync
- Edition inline des cellules.
- Correction du probleme de frappe rapide : la cellule ne remplace plus tout le texte quand l'utilisateur tape vite.
- Filtres rapides ajoutes :
  - Activite
  - Statut
  - Avec reliquat
  - Incompletes
- Recherche globale ajoutee.
- Ajout de ligne depuis la grille.
- Panneau lateral de detail de ligne.
- Resume compact en haut de grille :
  - Lignes
  - Eff facture
  - Eff paye
  - Attendu a date
  - Paye a date
  - Reliquat
- Bouton Import raccorde a la page Import.

#### Calculs

- Calcul du montant attendu mensuel :

```text
Eff facture x Tarif mensuel
```

- Calcul du montant attendu annuel :

```text
Montant attendu mensuel x 12
```

- Calcul du total paye.
- Calcul du reliquat annuel.
- Calcul du reliquat a date corrige selon la regle validee :
  - Annee passee : 12 mois pris en compte.
  - Annee courante : seulement les mois entierement clotures.
  - Annee future : 0 mois pris en compte.
- Exemple valide : le 19 juin 2026, janvier a mai sont pris en compte, juin ne l'est pas encore.
- Tests unitaires ajoutes pour proteger cette regle.

#### Dashboard

- Page Dashboard creee.
- Cartes KPI globales pour l'annee selectionnee.
- Distinction clarifiee entre :
  - Facturation : indicateurs de la vue filtree.
  - Dashboard : indicateurs globaux de l'annee.
- Liste des principaux reliquats.
- Repartition par activite.

#### Sauvegarde locale et sync MVP

- Sauvegarde locale via `shared_preferences`.
- Les lignes restent disponibles apres fermeture/reouverture de l'application.
- Indicateurs de sync visibles :
  - Synchronise
  - Modifie
  - Synchronisation
  - Erreur
- Mode hors ligne simule dans l'interface.
- Les modifications restent possibles en mode hors ligne.
- Reset local ajoute dans Parametres, visible uniquement en debug.
- Filtre d'erreur ajoute pour reduire le bruit connu du `RawKeyboard` Windows/Flutter sur la touche Alt.

#### Import Excel

- Debut de l'import Excel reel implemente.
- Dependances ajoutees :
  - `excel`
  - `file_picker`
- Service `BillingExcelImporter` cree.
- Lecture prevue des fichiers `.xlsx`.
- Parsing du format actuel du fichier :
  - deux lignes d'en-tete,
  - donnees a partir de la ligne metier,
  - colonnes de janvier a decembre,
  - ligne `TOTAUX` ignoree.
- Conversion des lignes Excel vers `BillingLine`.
- Signalement des problemes d'import :
  - references manquantes,
  - sites manquants,
  - references en doublon,
  - activites inconnues.
- Import autorise en brouillon si les references sont manquantes.
- Page Import transformee en vrai flux :
  - choisir un fichier Excel,
  - afficher le rapport,
  - afficher un apercu,
  - ajouter les lignes,
  - remplacer les donnees locales apres confirmation.
- Tests unitaires ajoutes pour le parseur Excel.

### 12.2 En cours ou a valider maintenant

Ces elements sont codes ou amorces, mais doivent etre valides dans l'application apres installation des nouvelles dependances.

- Lancer :

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
```

- Tester l'import du fichier `TEST FACTURATION.xlsx`.
- Verifier que le rapport d'import affiche bien les references manquantes du fichier de test.
- Verifier que `Ajouter les lignes` ajoute les lignes dans la grille.
- Verifier que `Remplacer local` remplace bien les donnees locales apres confirmation.
- Verifier que les lignes importees restent presentes apres fermeture/reouverture.
- Verifier que les activites inconnues restent visibles dans la grille au lieu d'etre remplacees silencieusement.

### 12.3 Reste a faire pour le MVP

#### Import Excel

- Valider l'import avec un vrai fichier de production contenant les references comptables.
- Ajouter un affichage plus detaille des erreurs ligne par ligne.
- Ajouter une option de mapping manuel si un futur fichier Excel change de structure.
- Ajouter une gestion plus fine des doublons lors de l'import :
  - ignorer,
  - remplacer,
  - fusionner uniquement l'annee,
  - garder les deux en brouillon.
- Detecter automatiquement l'annee depuis les colonnes mensuelles si possible.
- Gerer les fichiers `.xls` si le client en utilise encore.

#### Export Excel

- Construire l'export Excel reel.
- Produire un fichier proche du fichier actuel :
  - meme ordre des colonnes,
  - janvier a decembre,
  - total,
  - reliquat,
  - filtres Excel,
  - formats montants lisibles.
- Ajouter options d'export :
  - annee selectionnee,
  - vue filtree,
  - toutes les lignes,
  - uniquement les reliquats.

#### Grille et saisie

- Ameliorer la navigation clavier :
  - Enter,
  - Tab,
  - Shift + Tab,
  - fleches.
- Ajouter copier/coller depuis Excel si possible.
- Evaluer une vraie grille specialisee pour la suite :
  - Syncfusion Flutter DataGrid,
  - PlutoGrid,
  - TableView.
- Tester les performances avec :
  - 500 lignes,
  - 2 000 lignes,
  - 10 000 lignes.
- Ajouter colonnes figees si la solution de grille retenue le permet.

#### Sauvegarde locale et sync

- Remplacer progressivement `shared_preferences` par une vraie base locale desktop si necessaire :
  - Drift,
  - Isar,
  - autre solution stable Flutter desktop.
- Implementer une vraie outbox locale persistante.
- Integrer Firebase/Firestore.
- Implementer la synchronisation reelle en arriere-plan.
- Ajouter detection reseau reelle.
- Ajouter gestion des conflits cellule par cellule pour les paiements mensuels.
- Ajouter historique minimal des modifications.

#### Validation metier

- Rendre la reference obligatoire avant validation finale, sans bloquer le brouillon.
- Ajouter une validation claire des doublons de reference.
- Ajouter obligation de commentaire si statut `Autre`.
- Clarifier l'effet du statut `Desactive` sur les calculs si le client le demande.
- Ajouter des alertes non bloquantes pour :
  - effectif facture a 0,
  - montant mensuel a 0,
  - activite manquante ou inconnue,
  - reference manquante.

#### Dashboard

- Affiner les indicateurs avec les utilisateurs.
- Ajouter filtres dashboard si necessaire.
- Ajouter graphiques simples seulement s'ils apportent une vraie lecture.
- Ajouter comparaison entre annees plus tard si utile.

#### Parametres

- Ajouter gestion editable des activites si le client veut pouvoir les modifier.
- Ajouter annee par defaut.
- Ajouter options d'import/export.
- Garder le reset local uniquement en debug tant que le produit n'a pas de vraie gestion admin.

#### Authentification et droits

- Ajouter page Connexion si Firebase Auth est retenu.
- Definir les roles :
  - admin,
  - RH,
  - lecture seule,
  - comptabilite si necessaire.
- Restreindre les actions sensibles :
  - import,
  - remplacement local,
  - export complet,
  - parametres.

#### Tests et qualite

- Continuer les tests unitaires sur les calculs.
- Ajouter tests widget sur Import.
- Ajouter tests de persistence locale.
- Ajouter tests de parsing avec un fichier `.xlsx` genere.
- Tester Windows en priorite.
- Tester web ensuite.
- Faire un test utilisateur simple avec une personne RH.

### 12.4 Priorite recommandee de la suite

Ordre recommande :

1. Stabiliser et valider l'import Excel reel.
2. Construire l'export Excel reel.
3. Ameliorer la navigation clavier et le copier/coller.
4. Remplacer ou renforcer la grille si les performances deviennent insuffisantes.
5. Passer de la sauvegarde locale simple a une vraie base locale.
6. Integrer Firebase et la synchronisation reelle.
7. Ajouter authentification et droits.
8. Faire une passe UI/UX finale avec test utilisateur.

## 13. Evolutions futures

### V2

- Archivage au lieu de suppression.
- Historique detaille des modifications.
- Gestion des droits utilisateurs.
- Import Excel plus avance.
- Export par modele.
- Notifications de gros reliquats.
- Vues personnalisees par utilisateur.

### V3

- Module client.
- Module contrats.
- Module agents.
- Rapprochement comptable.
- Tableaux de bord avances.
- Workflow de validation.
- Application mobile de consultation.
