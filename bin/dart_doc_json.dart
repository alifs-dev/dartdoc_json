import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import '../lib/models.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Input file (export .dart) or directory', mandatory: true)
    ..addOption('output', abbr: 'o', help: 'Output JSON file (optional, defaults to input name + .json)')
    ..addOption('export-dir', help: 'Base directory for organizing output files by library structure')
    ..addFlag('help', abbr: 'h', help: 'Show usage', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Dart Documentation JSON Generator');
      print('Usage: dart run bin/dart_doc_json.dart -i <input> [-o <output>] [--export-dir <dir>]');
      print('\nExamples:');
      print('  # Analyze a directory');
      print('  dart run bin/dart_doc_json.dart -i lib -o docs.json');
      print('  # Analyze an export file (e.g., cupertino.dart)');
      print('  dart run bin/dart_doc_json.dart -i /path/to/cupertino.dart');
      print('  # Organize output by library structure');
      print('  dart run bin/dart_doc_json.dart -i /path/to/cupertino.dart --export-dir output/flutter');
      print(parser.usage);
      return;
    }

    final input = results['input'] as String;
    final exportDir = results['export-dir'] as String?;
    String? outputFile = results['output'] as String?;

    // Determine if input is a file or directory
    final inputFile = File(input);
    final inputDirectory = Directory(input);
    
    bool isExportFile = false;
    String baseDir = '';
    List<String> filesToAnalyze = [];

    if (inputFile.existsSync() && input.endsWith('.dart')) {
      // Input is an export file
      isExportFile = true;
      baseDir = p.dirname(input);
      print('Parsing export file: $input');
      filesToAnalyze = await parseExportFile(input, baseDir);
      print('Found ${filesToAnalyze.length} exported files');
      
      // Default output name based on input file
      if (outputFile == null) {
        final baseName = p.basenameWithoutExtension(input);
        outputFile = '$baseName.json';
      }
    } else if (inputDirectory.existsSync()) {
      // Input is a directory
      baseDir = input;
      filesToAnalyze = [input];
      
      // Default output name
      if (outputFile == null) {
        outputFile = 'documentation.json';
      }
    } else {
      print('Error: Input does not exist or is not a .dart file or directory: $input');
      exit(1);
    }

    // Validate output path is not a directory
    if (Directory(outputFile).existsSync()) {
      print('Error: Output path is a directory. Please specify a file path.');
      print('Example: -o $outputFile/documentation.json');
      exit(1);
    }

    if (exportDir != null) {
      // Organize output by library structure
      await analyzeAndOrganize(filesToAnalyze, baseDir, exportDir, isExportFile);
    } else {
      // Single output file
      final libraries = await analyzeFiles(filesToAnalyze, baseDir);
      
      print('Found ${libraries.length} libraries');
      
      final jsonOutput = libraries.map((lib) => lib.toJson()).toList();
      final jsonString = JsonEncoder.withIndent('  ').convert(jsonOutput);
      
      // Create output directory if it doesn't exist
      final outputDir = p.dirname(outputFile);
      if (outputDir != '.' && !Directory(outputDir).existsSync()) {
        Directory(outputDir).createSync(recursive: true);
      }
      
      await File(outputFile).writeAsString(jsonString);
      print('Documentation written to: $outputFile');
    }
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print(stackTrace);
    print(parser.usage);
    exit(1);
  }
}

/// Parse an export file to extract all exported file paths
Future<List<String>> parseExportFile(String exportFilePath, String baseDir) async {
  final content = await File(exportFilePath).readAsString();
  final exportPaths = <String>[];
  
  // Regex to match export statements: export 'path/to/file.dart';
  final exportRegex = RegExp(r'''export\s+['"]([^'"]+\.dart)['"]''');
  final matches = exportRegex.allMatches(content);
  
  for (final match in matches) {
    final relativePath = match.group(1)!;
    // Resolve relative path
    final absolutePath = p.normalize(p.join(baseDir, relativePath));
    if (File(absolutePath).existsSync()) {
      exportPaths.add(absolutePath);
    } else {
      print('Warning: Exported file not found: $absolutePath');
    }
  }
  
  return exportPaths;
}

/// Analyze files and organize output by library structure
Future<void> analyzeAndOrganize(List<String> filePaths, String baseDir, String exportDir, bool isExportFile) async {
  print('Analyzing ${filePaths.length} files...');
  
  for (final filePath in filePaths) {
    try {
      final libraries = await analyzeFiles([filePath], baseDir);
      
      if (libraries.isEmpty) continue;
      
      // Determine output path based on source file structure
      String outputPath;
      if (isExportFile) {
        // Extract relative path from base directory
        final relativePath = p.relative(filePath, from: baseDir);
        final relativeDir = p.dirname(relativePath);
        final baseName = p.basenameWithoutExtension(filePath);
        
        // Create directory structure
        final outputSubDir = p.join(exportDir, relativeDir);
        Directory(outputSubDir).createSync(recursive: true);
        
        outputPath = p.join(outputSubDir, '$baseName.json');
      } else {
        final baseName = p.basenameWithoutExtension(filePath);
        Directory(exportDir).createSync(recursive: true);
        outputPath = p.join(exportDir, '$baseName.json');
      }
      
      final jsonOutput = libraries.map((lib) => lib.toJson()).toList();
      final jsonString = JsonEncoder.withIndent('  ').convert(jsonOutput);
      
      await File(outputPath).writeAsString(jsonString);
      print('  ✓ ${p.relative(outputPath, from: exportDir)}');
    } catch (e) {
      print('  ✗ Error analyzing $filePath: $e');
    }
  }
  
  print('\nDocumentation written to: $exportDir/');
}

/// Analyze Dart files and return libraries
Future<List<DocLibrary>> analyzeFiles(List<String> paths, String baseDir) async {
  final libraries = <DocLibrary>[];
  
  for (final path in paths) {
    if (File(path).existsSync()) {
      // Single file
      final libs = await analyzeDartFiles(path);
      libraries.addAll(libs);
    } else if (Directory(path).existsSync()) {
      // Directory
      final libs = await analyzeDartFiles(path);
      libraries.addAll(libs);
    }
  }
  
  return libraries;
}

Future<List<DocLibrary>> analyzeDartFiles(String inputPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [p.absolute(inputPath)],
  );

  final libraries = <DocLibrary>[];

  for (final context in collection.contexts) {
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart')) continue;

      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) continue;

      final library = result.element;
      if (library.isPrivate) continue;

      libraries.add(await _processLibrary(library));
    }
  }

  return libraries;
}

Future<DocLibrary> _processLibrary(LibraryElement library) async {
  final classes = <DocClass>[];
  final enums = <DocEnum>[];
  final mixins = <DocMixin>[];
  final extensions = <DocExtension>[];
  final functions = <DocFunction>[];
  final variables = <DocVariable>[];

  for (final unit in library.units) {
    for (final element in unit.classes) {
      if (!element.isPrivate) {
        classes.add(_processClass(element));
      }
    }

    for (final element in unit.enums) {
      if (!element.isPrivate) {
        enums.add(_processEnum(element));
      }
    }

    for (final element in unit.mixins) {
      if (!element.isPrivate) {
        mixins.add(_processMixin(element));
      }
    }

    for (final element in unit.extensions) {
      if (element.name == null || !element.name!.startsWith('_')) {
        extensions.add(_processExtension(element));
      }
    }

    for (final element in unit.functions) {
      if (!element.isPrivate) {
        functions.add(_processFunction(element));
      }
    }

    for (final element in unit.topLevelVariables) {
      if (!element.isPrivate) {
        variables.add(_processVariable(element));
      }
    }
  }

  // Use filename (without .dart) if library name is empty
  final bool isAnonymous = library.name.isEmpty;
  String libraryName = library.name;
  if (isAnonymous && library.definingCompilationUnit.source.uri.pathSegments.isNotEmpty) {
    final fileName = library.definingCompilationUnit.source.uri.pathSegments.last;
    libraryName = fileName.replaceAll('.dart', '');
  }

  return DocLibrary(
    name: libraryName,
    isAnonymous: isAnonymous,
    documentation: _cleanDocumentation(library.documentationComment),
    classes: classes,
    enums: enums,
    mixins: mixins,
    extensions: extensions,
    functions: functions,
    variables: variables,
  );
}

/// Clean documentation by removing /// and // while preserving newlines
String? _cleanDocumentation(String? doc) {
  if (doc == null) return null;
  
  // Split by lines
  final lines = doc.split('\n');
  final cleanedLines = <String>[];
  
  for (var line in lines) {
    // Remove leading /// or //
    line = line.trimLeft();
    if (line.startsWith('///')) {
      line = line.substring(3).trimLeft();
    } else if (line.startsWith('//')) {
      line = line.substring(2).trimLeft();
    }
    cleanedLines.add(line);
  }
  
  return cleanedLines.join('\n').trim();
}

DocClass _processClass(ClassElement element) {
  return DocClass(
    name: element.name,
    documentation: _cleanDocumentation(element.documentationComment),
    isAbstract: element.isAbstract,
    isSealed: element.isSealed,
    isFinal: element.isFinal,
    isBase: element.isBase,
    isMixinClass: element.isMixinClass,
    typeParameters: element.typeParameters.map((tp) => tp.name).toList(),
    superclass: element.supertype?.getDisplayString(),
    interfaces: element.interfaces.map((i) => i.getDisplayString()).toList(),
    mixins: element.mixins.map((m) => m.getDisplayString()).toList(),
    constructors: element.constructors
        .where((c) => !c.isPrivate)
        .map((c) => _processConstructor(c))
        .toList(),
    fields: element.fields
        .where((f) => !f.isPrivate && !f.isSynthetic)
        .map((f) => _processField(f))
        .toList(),
    methods: element.methods
        .where((m) => !m.isPrivate)
        .map((m) => _processMethod(m))
        .toList(),
  );
}

DocEnum _processEnum(EnumElement element) {
  return DocEnum(
    name: element.name,
    documentation: _cleanDocumentation(element.documentationComment),
    values: element.fields
        .where((f) => f.isEnumConstant)
        .map((f) => DocEnumValue(
              name: f.name,
              documentation: _cleanDocumentation(f.documentationComment),
            ))
        .toList(),
    fields: element.fields
        .where((f) => !f.isPrivate && !f.isSynthetic && !f.isEnumConstant)
        .map((f) => _processField(f))
        .toList(),
    methods: element.methods
        .where((m) => !m.isPrivate)
        .map((m) => _processMethod(m))
        .toList(),
  );
}

DocMixin _processMixin(MixinElement element) {
  return DocMixin(
    name: element.name,
    documentation: _cleanDocumentation(element.documentationComment),
    typeParameters: element.typeParameters.map((tp) => tp.name).toList(),
    on: element.superclassConstraints.map((s) => s.getDisplayString()).toList(),
    interfaces: element.interfaces.map((i) => i.getDisplayString()).toList(),
    fields: element.fields
        .where((f) => !f.isPrivate && !f.isSynthetic)
        .map((f) => _processField(f))
        .toList(),
    methods: element.methods
        .where((m) => !m.isPrivate)
        .map((m) => _processMethod(m))
        .toList(),
  );
}

DocExtension _processExtension(ExtensionElement element) {
  return DocExtension(
    name: element.name,
    documentation: _cleanDocumentation(element.documentationComment),
    extendedType: element.extendedType.getDisplayString(),
    fields: element.fields
        .where((f) => !f.isPrivate && !f.isSynthetic)
        .map((f) => _processField(f))
        .toList(),
    methods: element.methods
        .where((m) => !m.isPrivate)
        .map((m) => _processMethod(m))
        .toList(),
  );
}

DocConstructor _processConstructor(ConstructorElement element) {
  return DocConstructor(
    name: element.name.isEmpty ? element.enclosingElement3.name : '${element.enclosingElement3.name}.${element.name}',
    documentation: _cleanDocumentation(element.documentationComment),
    isConst: element.isConst,
    isFactory: element.isFactory,
    parameters: element.parameters.map((p) => _processParameter(p)).toList(),
  );
}

DocField _processField(FieldElement element) {
  return DocField(
    name: element.name,
    type: element.type.getDisplayString(),
    documentation: _cleanDocumentation(element.documentationComment),
    isStatic: element.isStatic,
    isConst: element.isConst,
    isFinal: element.isFinal,
    isLate: element.isLate,
  );
}

DocMethod _processMethod(MethodElement element) {
  return DocMethod(
    name: element.name,
    returnType: element.returnType.getDisplayString(),
    documentation: _cleanDocumentation(element.documentationComment),
    isStatic: element.isStatic,
    isAbstract: element.isAbstract,
    typeParameters: element.typeParameters.map((tp) => tp.name).toList(),
    parameters: element.parameters.map((p) => _processParameter(p)).toList(),
  );
}

DocFunction _processFunction(FunctionElement element) {
  return DocFunction(
    name: element.name,
    returnType: element.returnType.getDisplayString(),
    documentation: _cleanDocumentation(element.documentationComment),
    typeParameters: element.typeParameters.map((tp) => tp.name).toList(),
    parameters: element.parameters.map((p) => _processParameter(p)).toList(),
  );
}

DocVariable _processVariable(TopLevelVariableElement element) {
  return DocVariable(
    name: element.name,
    type: element.type.getDisplayString(),
    documentation: _cleanDocumentation(element.documentationComment),
    isConst: element.isConst,
    isFinal: element.isFinal,
    isLate: element.isLate,
  );
}

DocParameter _processParameter(ParameterElement element) {
  return DocParameter(
    name: element.name,
    type: element.type.getDisplayString(),
    isRequired: element.isRequired,
    isNamed: element.isNamed,
    defaultValue: element.defaultValueCode,
  );
}
