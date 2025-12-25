/// Data models for JSON serialization of Dart documentation.

class DocLibrary {
  final String name;
  final String? documentation;
  final List<DocClass> classes;
  final List<DocEnum> enums;
  final List<DocMixin> mixins;
  final List<DocExtension> extensions;
  final List<DocFunction> functions;
  final List<DocVariable> variables;

  DocLibrary({
    required this.name,
    this.documentation,
    required this.classes,
    required this.enums,
    required this.mixins,
    required this.extensions,
    required this.functions,
    required this.variables,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'classes': classes.map((c) => c.toJson()).toList(),
        'enums': enums.map((e) => e.toJson()).toList(),
        'mixins': mixins.map((m) => m.toJson()).toList(),
        'extensions': extensions.map((e) => e.toJson()).toList(),
        'functions': functions.map((f) => f.toJson()).toList(),
        'variables': variables.map((v) => v.toJson()).toList(),
      };
}

class DocClass {
  final String name;
  final String? documentation;
  final bool isAbstract;
  final bool isSealed;
  final bool isFinal;
  final bool isBase;
  final bool isMixinClass;
  final List<String> typeParameters;
  final String? superclass;
  final List<String> interfaces;
  final List<String> mixins;
  final List<DocConstructor> constructors;
  final List<DocField> fields;
  final List<DocMethod> methods;

  DocClass({
    required this.name,
    this.documentation,
    required this.isAbstract,
    required this.isSealed,
    required this.isFinal,
    required this.isBase,
    required this.isMixinClass,
    required this.typeParameters,
    this.superclass,
    required this.interfaces,
    required this.mixins,
    required this.constructors,
    required this.fields,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'isAbstract': isAbstract,
        'isSealed': isSealed,
        'isFinal': isFinal,
        'isBase': isBase,
        'isMixinClass': isMixinClass,
        'typeParameters': typeParameters,
        'superclass': superclass,
        'interfaces': interfaces,
        'mixins': mixins,
        'constructors': constructors.map((c) => c.toJson()).toList(),
        'fields': fields.map((f) => f.toJson()).toList(),
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class DocEnum {
  final String name;
  final String? documentation;
  final List<DocEnumValue> values;
  final List<DocField> fields;
  final List<DocMethod> methods;

  DocEnum({
    required this.name,
    this.documentation,
    required this.values,
    required this.fields,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'values': values.map((v) => v.toJson()).toList(),
        'fields': fields.map((f) => f.toJson()).toList(),
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class DocEnumValue {
  final String name;
  final String? documentation;

  DocEnumValue({required this.name, this.documentation});

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
      };
}

class DocMixin {
  final String name;
  final String? documentation;
  final List<String> typeParameters;
  final List<String> on;
  final List<String> interfaces;
  final List<DocField> fields;
  final List<DocMethod> methods;

  DocMixin({
    required this.name,
    this.documentation,
    required this.typeParameters,
    required this.on,
    required this.interfaces,
    required this.fields,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'typeParameters': typeParameters,
        'on': on,
        'interfaces': interfaces,
        'fields': fields.map((f) => f.toJson()).toList(),
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class DocExtension {
  final String? name;
  final String? documentation;
  final String extendedType;
  final List<DocField> fields;
  final List<DocMethod> methods;

  DocExtension({
    this.name,
    this.documentation,
    required this.extendedType,
    required this.fields,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'extendedType': extendedType,
        'fields': fields.map((f) => f.toJson()).toList(),
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class DocConstructor {
  final String name;
  final String? documentation;
  final bool isConst;
  final bool isFactory;
  final List<DocParameter> parameters;

  DocConstructor({
    required this.name,
    this.documentation,
    required this.isConst,
    required this.isFactory,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'documentation': documentation,
        'isConst': isConst,
        'isFactory': isFactory,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };
}

class DocField {
  final String name;
  final String type;
  final String? documentation;
  final bool isStatic;
  final bool isConst;
  final bool isFinal;
  final bool isLate;

  DocField({
    required this.name,
    required this.type,
    this.documentation,
    required this.isStatic,
    required this.isConst,
    required this.isFinal,
    required this.isLate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'documentation': documentation,
        'isStatic': isStatic,
        'isConst': isConst,
        'isFinal': isFinal,
        'isLate': isLate,
      };
}

class DocMethod {
  final String name;
  final String returnType;
  final String? documentation;
  final bool isStatic;
  final bool isAbstract;
  final List<String> typeParameters;
  final List<DocParameter> parameters;

  DocMethod({
    required this.name,
    required this.returnType,
    this.documentation,
    required this.isStatic,
    required this.isAbstract,
    required this.typeParameters,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'returnType': returnType,
        'documentation': documentation,
        'isStatic': isStatic,
        'isAbstract': isAbstract,
        'typeParameters': typeParameters,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };
}

class DocFunction {
  final String name;
  final String returnType;
  final String? documentation;
  final List<String> typeParameters;
  final List<DocParameter> parameters;

  DocFunction({
    required this.name,
    required this.returnType,
    this.documentation,
    required this.typeParameters,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'returnType': returnType,
        'documentation': documentation,
        'typeParameters': typeParameters,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };
}

class DocVariable {
  final String name;
  final String type;
  final String? documentation;
  final bool isConst;
  final bool isFinal;
  final bool isLate;

  DocVariable({
    required this.name,
    required this.type,
    this.documentation,
    required this.isConst,
    required this.isFinal,
    required this.isLate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'documentation': documentation,
        'isConst': isConst,
        'isFinal': isFinal,
        'isLate': isLate,
      };
}

class DocParameter {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;

  DocParameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'isRequired': isRequired,
        'isNamed': isNamed,
        'defaultValue': defaultValue,
      };
}
