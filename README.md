# Dart Documentation to JSON

A command-line tool that generates JSON documentation from Dart source code, similar to `dartdoc` but with JSON output instead of HTML.

## Features

- 📦 Analyzes entire directories of Dart files
- 🔍 Extracts comprehensive documentation from code
- 🎯 Supports all Dart language constructs:
  - Classes (including sealed, abstract, base, final, mixin classes)
  - Enums with enhanced features
  - Mixins with constraints
  - Extensions
  - Top-level functions and variables
- 📝 Captures documentation comments
- 🔤 Preserves full type information with nullability
- 🚫 Filters out private elements automatically
- 📄 Generates clean, structured JSON output

## Installation

1. Ensure you have Dart SDK 3.0.0 or higher installed
2. Clone this repository
3. Install dependencies:

```bash
dart pub get
```

## Usage

### Basic Command

```bash
dart run bin/dart_doc_json.dart -i <input_directory> -o <output_file>
```

### Options

- `-i, --input` (required): Input directory containing Dart files
- `-o, --output` (optional): Output JSON file (default: `documentation.json`)
- `-h, --help`: Show usage information

### Examples

```bash
# Analyze lib directory and output to documentation.json
dart run bin/dart_doc_json.dart -i lib

# Analyze specific directory with custom output
dart run bin/dart_doc_json.dart -i src -o docs/api.json

# Analyze entire project
dart run bin/dart_doc_json.dart -i . -o full_documentation.json
```

## Output Format

The tool generates a JSON array of libraries. Each library contains:

```json
[
  {
    "name": "library_name",
    "documentation": "Library documentation comment",
    "classes": [...],
    "enums": [...],
    "mixins": [...],
    "extensions": [...],
    "functions": [...],
    "variables": [...]
  }
]
```

### Class Documentation

Each class includes:
- Name and documentation
- Modifiers (abstract, sealed, final, base, mixin class)
- Type parameters
- Superclass and interfaces
- Mixins
- Constructors with parameters
- Fields with types and modifiers
- Methods with return types and parameters

### Example Output

```json
{
  "name": "MyClass",
  "documentation": "/// A sample class",
  "isAbstract": false,
  "isSealed": false,
  "isFinal": false,
  "typeParameters": ["T"],
  "superclass": "Object",
  "interfaces": ["Comparable<MyClass>"],
  "mixins": [],
  "constructors": [
    {
      "name": "MyClass",
      "documentation": null,
      "isConst": false,
      "isFactory": false,
      "parameters": [...]
    }
  ],
  "fields": [...],
  "methods": [...]
}
```

## How It Works

1. Uses the Dart `analyzer` package to parse source files
2. Traverses the AST to extract all public symbols
3. Captures documentation comments and metadata
4. Serializes to JSON using custom data models
5. Writes formatted JSON to the output file

## Dependencies

- `analyzer: ^6.0.0` - Dart code analysis
- `path: ^1.8.0` - Path manipulation
- `args: ^2.4.0` - Command-line argument parsing

## License

This project is provided as-is for documentation generation purposes.

## Contributing

Feel free to submit issues or pull requests for improvements!
