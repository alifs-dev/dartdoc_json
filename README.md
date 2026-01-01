# Dart Documentation to JSON

Un outil en ligne de commande qui génère de la documentation JSON à partir du code source Dart, similaire à `dartdoc` mais avec une sortie JSON au lieu de HTML.

## Fonctionnalités

- 📦 Analyse des répertoires entiers ou des fichiers d'export Flutter
- 🔍 Extraction complète de la documentation du code
- 🎯 Support de toutes les constructions du langage Dart:
  - Classes (sealed, abstract, base, final, mixin classes)
  - Enums avec fonctionnalités avancées
  - Mixins avec contraintes
  - Extensions
  - Fonctions et variables de niveau supérieur
- 📝 Documentation nettoyée (suppression des `///` et `//`)
- 🔤 Préservation complète des informations de type avec nullabilité
- 🚫 Filtrage automatique des éléments privés
- 📄 Génération de JSON propre et structuré
- 🗂️ Organisation par structure de bibliothèque (optionnel)
- ⚡ Nom de sortie automatique basé sur le fichier d'entrée

## Installation

1. Assurez-vous d'avoir Dart SDK 3.0.0 ou supérieur installé
2. Clonez ce dépôt
3. Installez les dépendances:

```bash
dart pub get
```

## Utilisation

### Commandes de Base

```bash
dart run bin/dart_doc_json.dart -i <input> [-o <output>] [--export-dir <dir>]
```

### Options

- `-i, --input` (requis): Fichier d'export `.dart` ou répertoire contenant des fichiers Dart
- `-o, --output` (optionnel): Fichier JSON de sortie (par défaut: nom du fichier d'entrée + `.json`)
- `--export-dir` (optionnel): Répertoire de base pour organiser les fichiers de sortie par structure de bibliothèque
- `-h, --help`: Afficher l'aide

### Exemples

**1. Analyser un fichier d'export Flutter:**
```bash
dart run bin/dart_doc_json.dart -i /path/to/flutter/lib/cupertino.dart
# Sortie: cupertino.json (nom automatique)
```

**2. Analyser avec nom de sortie personnalisé:**
```bash
dart run bin/dart_doc_json.dart -i /path/to/cupertino.dart -o docs/cupertino.json
```

**3. Organiser par structure de répertoires:**
```bash
dart run bin/dart_doc_json.dart -i /path/to/cupertino.dart --export-dir output/flutter
# Sortie: output/flutter/src/cupertino/*.json (un fichier par source)
```

**4. Analyser un répertoire:**
```bash
dart run bin/dart_doc_json.dart -i lib -o documentation.json
```

**5. Analyser Flutter Cupertino complet:**
```bash
dart run bin/dart_doc_json.dart \
  -i /home/ali/snap/flutter/common/flutter/packages/flutter/lib/cupertino.dart \
  --export-dir output/flutter
```

## Nouvelles Fonctionnalités

### 🆕 Parsing de Fichiers d'Export

L'outil peut maintenant analyser les fichiers d'export Flutter (comme `cupertino.dart`, `material.dart`) et extraire automatiquement tous les fichiers référencés.

**Exemple:** Le fichier `cupertino.dart` exporte 50 fichiers - tous sont analysés automatiquement!

### 🆕 Nom de Sortie Automatique

L'option `--output` est maintenant optionnelle. Si non spécifiée:
- Fichier d'export: `cupertino.dart` → `cupertino.json`
- Répertoire: `documentation.json` (par défaut)

### 🆕 Organisation par Structure de Bibliothèque

Avec `--export-dir`, les fichiers sont organisés selon la structure source:

```
output/flutter/
└── src/
    └── cupertino/
        ├── activity_indicator.json
        ├── app.json
        ├── button.json
        └── ...
```

### 🆕 Documentation Nettoyée

La documentation est maintenant propre et lisible:
- ✅ Suppression des `///` et `//`
- ✅ Préservation des `\n` pour la structure

**Avant:**
```json
"documentation": "/// An iOS-style activity indicator"
```

**Après:**
```json
"documentation": "An iOS-style activity indicator"
```

## Format de Sortie

L'outil génère un tableau JSON de bibliothèques. Chaque bibliothèque contient:

```json
[
  {
    "name": "library_name",
    "documentation": "Library documentation",
    "classes": [...],
    "enums": [...],
    "mixins": [...],
    "extensions": [...],
    "functions": [...],
    "variables": [...]
  }
]
```

### Documentation de Classe

Chaque classe inclut:
- Nom et documentation
- Modificateurs (abstract, sealed, final, base, mixin class)
- Paramètres de type
- Superclasse et interfaces
- Mixins
- Constructeurs avec paramètres
- Champs avec types et modificateurs
- Méthodes avec types de retour et paramètres

### Exemple de Sortie

```json
{
  "name": "CupertinoActivityIndicator",
  "documentation": "An iOS-style activity indicator that spins clockwise.\n\nSee also:\n\n* <https://developer.apple.com/design/...>",
  "isAbstract": false,
  "isSealed": false,
  "typeParameters": [],
  "superclass": "StatefulWidget",
  "constructors": [
    {
      "name": "CupertinoActivityIndicator",
      "documentation": "Creates an iOS-style activity indicator that spins clockwise.",
      "isConst": true,
      "parameters": [
        {
          "name": "color",
          "type": "Color?",
          "isRequired": false,
          "isNamed": true
        }
      ]
    }
  ],
  "fields": [...],
  "methods": [...]
}
```

## Comment Ça Marche

1. **Parsing d'Export**: Utilise regex pour extraire les chemins des `export 'path/to/file.dart';`
2. **Analyse**: Utilise le package `analyzer` de Dart pour parser les fichiers source
3. **Extraction**: Traverse l'AST pour extraire tous les symboles publics
4. **Nettoyage**: Supprime les `///` et `//` de la documentation
5. **Sérialisation**: Convertit en JSON avec des modèles de données personnalisés
6. **Organisation**: Crée la structure de répertoires si `--export-dir` est spécifié

## Dépendances

- `analyzer: ^6.0.0` - Analyse de code Dart
- `path: ^1.8.0` - Manipulation de chemins
- `args: ^2.4.0` - Parsing d'arguments en ligne de commande

## Exemples Pratiques

### Analyser Toutes les Bibliothèques Flutter

```bash
# Cupertino
dart run bin/dart_doc_json.dart \
  -i /path/to/flutter/lib/cupertino.dart \
  --export-dir output/flutter

# Material
dart run bin/dart_doc_json.dart \
  -i /path/to/flutter/lib/material.dart \
  --export-dir output/flutter

# Widgets
dart run bin/dart_doc_json.dart \
  -i /path/to/flutter/lib/widgets.dart \
  --export-dir output/flutter
```

### Analyser Votre Propre Bibliothèque

```bash
# Fichier unique
dart run bin/dart_doc_json.dart -i lib/my_library.dart

# Répertoire complet
dart run bin/dart_doc_json.dart -i lib -o my_docs.json
```

## Licence

Ce projet est fourni tel quel pour la génération de documentation.

## Contribution

N'hésitez pas à soumettre des issues ou des pull requests pour des améliorations!
