class OperationalReportContent {
  const OperationalReportContent({
    required this.generalInformation,
    required this.occurrenceNarrative,
    required this.developmentNarrative,
    required this.teams,
    required this.resources,
    required this.conclusion,
  });

  static const empty = OperationalReportContent(
    generalInformation: OperationalGeneralInformation.empty,
    occurrenceNarrative: '',
    developmentNarrative: '',
    teams: <OperationalTeam>[],
    resources: <OperationalResource>[],
    conclusion: '',
  );

  final OperationalGeneralInformation generalInformation;
  final String occurrenceNarrative;
  final String developmentNarrative;
  final List<OperationalTeam> teams;
  final List<OperationalResource> resources;
  final String conclusion;

  factory OperationalReportContent.fromLegacy({
    required List<String> teams,
    required List<String> resources,
    required String conclusion,
  }) =>
      OperationalReportContent(
        generalInformation: OperationalGeneralInformation.empty,
        occurrenceNarrative: '',
        developmentNarrative: '',
        teams: teams
            .map(
              (value) => OperationalTeam(
                name: value,
                members: const <String>[],
              ),
            )
            .toList(growable: false),
        resources: resources
            .map(
              (value) => OperationalResource(
                description: value,
                purpose: '',
              ),
            )
            .toList(growable: false),
        conclusion: conclusion,
      );

  OperationalReportContent copyWith({
    OperationalGeneralInformation? generalInformation,
    String? occurrenceNarrative,
    String? developmentNarrative,
    List<OperationalTeam>? teams,
    List<OperationalResource>? resources,
    String? conclusion,
  }) =>
      OperationalReportContent(
        generalInformation: generalInformation ?? this.generalInformation,
        occurrenceNarrative: occurrenceNarrative ?? this.occurrenceNarrative,
        developmentNarrative:
            developmentNarrative ?? this.developmentNarrative,
        teams: teams ?? this.teams,
        resources: resources ?? this.resources,
        conclusion: conclusion ?? this.conclusion,
      );

  Map<String, dynamic> toJson() => {
        'generalInformation': generalInformation.toJson(),
        'occurrenceNarrative': occurrenceNarrative,
        'developmentNarrative': developmentNarrative,
        'teams': teams.map((item) => item.toJson()).toList(),
        'resources': resources.map((item) => item.toJson()).toList(),
        'conclusion': conclusion,
      };

  factory OperationalReportContent.fromJson(Map<String, dynamic> json) =>
      OperationalReportContent(
        generalInformation: OperationalGeneralInformation.fromJson(
          Map<String, dynamic>.from(
            json['generalInformation'] as Map? ?? const {},
          ),
        ),
        occurrenceNarrative: json['occurrenceNarrative'] as String? ?? '',
        developmentNarrative:
            json['developmentNarrative'] as String? ?? '',
        teams: (json['teams'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => OperationalTeam.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
        resources: (json['resources'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => OperationalResource.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
        conclusion: json['conclusion'] as String? ?? '',
      );
}

class OperationalGeneralInformation {
  const OperationalGeneralInformation({
    required this.externalReference,
    required this.documentRg,
    required this.documentCpf,
    required this.phone,
    required this.contactMadeBy,
  });

  static const empty = OperationalGeneralInformation(
    externalReference: '',
    documentRg: '',
    documentCpf: '',
    phone: '',
    contactMadeBy: '',
  );

  final String externalReference;
  final String documentRg;
  final String documentCpf;
  final String phone;
  final String contactMadeBy;

  OperationalGeneralInformation copyWith({
    String? externalReference,
    String? documentRg,
    String? documentCpf,
    String? phone,
    String? contactMadeBy,
  }) =>
      OperationalGeneralInformation(
        externalReference: externalReference ?? this.externalReference,
        documentRg: documentRg ?? this.documentRg,
        documentCpf: documentCpf ?? this.documentCpf,
        phone: phone ?? this.phone,
        contactMadeBy: contactMadeBy ?? this.contactMadeBy,
      );

  Map<String, dynamic> toJson() => {
        'externalReference': externalReference,
        'documentRg': documentRg,
        'documentCpf': documentCpf,
        'phone': phone,
        'contactMadeBy': contactMadeBy,
      };

  factory OperationalGeneralInformation.fromJson(
    Map<String, dynamic> json,
  ) =>
      OperationalGeneralInformation(
        externalReference: json['externalReference'] as String? ?? '',
        documentRg: json['documentRg'] as String? ?? '',
        documentCpf: json['documentCpf'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        contactMadeBy: json['contactMadeBy'] as String? ?? '',
      );
}

class OperationalTeam {
  const OperationalTeam({
    required this.name,
    required this.members,
  });

  final String name;
  final List<String> members;

  String get legacySummary {
    if (members.isEmpty) return name;
    if (name.isEmpty) return members.join(', ');
    return '$name: ${members.join(', ')}';
  }

  OperationalTeam copyWith({
    String? name,
    List<String>? members,
  }) =>
      OperationalTeam(
        name: name ?? this.name,
        members: members ?? this.members,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'members': members,
      };

  factory OperationalTeam.fromJson(Map<String, dynamic> json) =>
      OperationalTeam(
        name: json['name'] as String? ?? '',
        members: List<String>.from(
          json['members'] as List? ?? const [],
        ),
      );
}

class OperationalResource {
  const OperationalResource({
    required this.description,
    required this.purpose,
  });

  final String description;
  final String purpose;

  String get legacySummary {
    if (purpose.isEmpty) return description;
    if (description.isEmpty) return purpose;
    return '$description ($purpose)';
  }

  OperationalResource copyWith({
    String? description,
    String? purpose,
  }) =>
      OperationalResource(
        description: description ?? this.description,
        purpose: purpose ?? this.purpose,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'purpose': purpose,
      };

  factory OperationalResource.fromJson(Map<String, dynamic> json) =>
      OperationalResource(
        description: json['description'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
      );
}
