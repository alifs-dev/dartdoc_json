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
    ..addOption('input', abbr: 'i', help: 'Input directory containing Dart files', mandatory: true)
    ..addOption('output', abbr: 'o', help: 'Output JSON file', defaultsTo: 'documentation.json')
    ..addFlag('help', abbr: 'h', help: 'Show usage', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Dart Documentation JSON Generator');
      print('Usage: dart run bin/dart_doc_json.dart -i <input_dir> -o <output_file>');
      print(parser.usage);
      return;
    }

    final inputDir = results['input'] as String;
    final outputFile = results['output'] as String;

    if (!Directory(inputDir).existsSync()) {
      print('Error: Input directory does not exist: $inputDir');
      exit(1);
    }

    // Validate output path is not a directory
    if (Directory(outputFile).existsSync()) {
      print('Error: Output path is a directory. Please specify a file path.');
      print('Example: -o $outputFile/documentation.json');
      exit(1);
    }

    // Create output directory if it doesn't exist
    final outputDir = p.dirname(outputFile);
    if (outputDir != '.' && !Directory(outputDir).existsSync()) {
      Directory(outputDir).createSync(recursive: true);
    }

    print('Analyzing Dart files in: $inputDir');
    final libraries = await analyzeDartFiles(inputDir);
    
    print('Found ${libraries.length} libraries');
    
    final jsonOutput = libraries.map((lib) => lib.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonOutput);
    
    await File(outputFile).writeAsString(jsonString);
    print('Documentation written to: $outputFile');
    
  } catch (e) {
    print('Error: $e');
    print(parser.usage);
    exit(1);
  }
}

Future<List<DocLibrary>> analyzeDartFiles(String inputDir) async {
  final collection = AnalysisContextCollection(
    includedPaths: [p.absolute(inputDir)],
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

  return DocLibrary(
    name: library.name,
    documentation: library.documentationComment,
    classes: classes,
    enums: enums,
    mixins: mixins,
    extensions: extensions,
    functions: functions,
    variables: variables,
  );
}

DocClass _processClass(ClassElement element) {
  return DocClass(
    name: element.name,
    documentation: element.documentationComment,
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
    documentation: element.documentationComment,
    values: element.fields
        .where((f) => f.isEnumConstant)
        .map((f) => DocEnumValue(
              name: f.name,
              documentation: f.documentationComment,
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
    documentation: element.documentationComment,
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
    documentation: element.documentationComment,
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
    documentation: element.documentationComment,
    isConst: element.isConst,
    isFactory: element.isFactory,
    parameters: element.parameters.map((p) => _processParameter(p)).toList(),
  );
}

DocField _processField(FieldElement element) {
  return DocField(
    name: element.name,
    type: element.type.getDisplayString(),
    documentation: element.documentationComment,
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
    documentation: element.documentationComment,
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
    documentation: element.documentationComment,
    typeParameters: element.typeParameters.map((tp) => tp.name).toList(),
    parameters: element.parameters.map((p) => _processParameter(p)).toList(),
  );
}

DocVariable _processVariable(TopLevelVariableElement element) {
  return DocVariable(
    name: element.name,
    type: element.type.getDisplayString(),
    documentation: element.documentationComment,
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
