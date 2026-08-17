# Bash Tools

Outils Bash pour automatiser des tâches réelles sous Linux avec une priorité claire : **analyser avant de modifier**.

Ce dépôt est une **édition publique reconstruite et assainie** à partir de besoins et d’outils que j’utilise dans mon environnement personnel. Il ne prétend pas reproduire bit à bit toutes mes anciennes versions locales.

## Objectif

Transformer des opérations répétitives — inventaire, renommage, traitement récursif et conversion par lots — en processus reproductibles, contrôlables et faciles à vérifier.

Principes utilisés :

```text
Observer → Analyser → Simuler → Valider → Exécuter → Vérifier
```

## Outils publiés

### `tree_inventory.sh`

Génère une représentation hiérarchique d’un répertoire sans dépendre de la commande `tree`.

Fonctions principales :

- parcours récursif ;
- conservation de la relation parent/enfant ;
- fichiers et dossiers, ou dossiers seulement ;
- profondeur maximale configurable ;
- sortie terminal ou fichier ;
- compteurs de fichiers et répertoires.

```bash
bash scripts/tree_inventory.sh --max-depth 3 /chemin/a/analyser
bash scripts/tree_inventory.sh --dirs-only --output inventaire.txt /chemin/a/analyser
```

### `normalize_authors.sh`

Normalise des répertoires d’auteurs écrits sous la forme `Nom, Prénom`.

```text
Coelho, Paulo/ → Paulo Coelho/
Camus, Albert/ → Albert Camus/
```

Le script fonctionne en **dry-run par défaut**. Une modification réelle exige explicitement `--apply`.

```bash
bash scripts/normalize_authors.sh --recursive /bibliotheque
bash scripts/normalize_authors.sh --apply --recursive /bibliotheque
```

Les collisions et noms ambigus ne sont pas écrasés silencieusement.

### `lit2epub.sh`

Conversion par lots de fichiers Microsoft Reader `.lit` vers `.epub` avec `ebook-convert` de Calibre.

Fonctions principales :

- dry-run par défaut ;
- récursivité optionnelle ;
- gestion des destinations existantes ;
- suppression de la source uniquement après conversion réussie ;
- fichier temporaire pendant la conversion ;
- nettoyage d’une sortie incomplète ;
- journalisation optionnelle ;
- compteurs de résultat.

```bash
bash scripts/lit2epub.sh --recursive /bibliotheque
bash scripts/lit2epub.sh --apply --recursive --log conversion.log /bibliotheque
```

Dépendance pour l’exécution réelle : **Calibre / `ebook-convert`**.

## Sécurité des opérations

Les scripts pouvant modifier des données privilégient un comportement conservateur :

- aucune modification par défaut ;
- option `--apply` explicite ;
- détection de collisions ;
- chemins protégés par guillemets et `--` lorsque pertinent ;
- traitement compatible avec espaces et caractères accentués ;
- codes de sortie non nuls lorsqu’une erreur de traitement survient.

Avant toute utilisation sur des données importantes, une sauvegarde reste recommandée.

## Tests

Un test de fumée vérifie la syntaxe et les comportements essentiels sans toucher aux données de l’utilisateur :

```bash
bash tests/smoke.sh
```

Le test crée son propre répertoire temporaire, vérifie les modes dry-run et apply pour la normalisation et valide le dry-run de la conversion `.lit → .epub`.

## Structure

```text
bash-tools/
├── README.md
├── .gitignore
├── scripts/
│   ├── tree_inventory.sh
│   ├── normalize_authors.sh
│   └── lit2epub.sh
└── tests/
    └── smoke.sh
```

## Évolutions prévues

Les versions locales historiques incluent ou ont exploré des besoins plus larges : organisation de livres à partir de métadonnées EPUB, inventaire de films et séries, gestion des cas ambigus via une zone `_REVISAR/`, rapports plus détaillés et outils interactifs plus complets.

Ces fonctions seront publiées progressivement seulement après révision du code et des cas limites.

## Portfolio

Cas technique détaillé :

https://fagobo.com/gonzy/career/projects/bash-tools/

Profil professionnel :

https://fagobo.com/gonzy/career/

---

**Sigfrido Gonzalez Puga · Gonzy**  
Linux · Bash · Automatisation · Support applicatif · Systèmes
