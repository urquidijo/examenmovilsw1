class TramiteTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TramiteField> fields;

  TramiteTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.fields,
  });

  factory TramiteTemplate.fromJson(Map<String, dynamic> json) {
    return TramiteTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Trámite',
      description: json['description'],
      fields: ((json['fields'] ?? []) as List)
          .map((item) => TramiteField.fromJson(item))
          .toList(),
    );
  }
}

class TramiteField {
  final String id;
  final String label;
  final String type;
  final String? placeholder;
  final bool required;
  final List<String> options;

  TramiteField({
    required this.id,
    required this.label,
    required this.type,
    this.placeholder,
    required this.required,
    required this.options,
  });

  factory TramiteField.fromJson(Map<String, dynamic> json) {
    return TramiteField(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Campo',
      type: json['type'] ?? 'TEXT',
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      options: ((json['options'] ?? []) as List)
          .map((item) => item.toString())
          .toList(),
    );
  }
}