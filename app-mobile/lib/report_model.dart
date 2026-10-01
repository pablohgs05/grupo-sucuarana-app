class Report {
  const Report({
    required this.id,
    required this.identification,
    required this.missing,
    required this.operation,
    required this.physicalDescription,
    required this.clothing,
    required this.health,
    required this.procedures,
    required this.teams,
    required this.resources,
    required this.conclusion,
    required this.attachments,
    required this.updatedAt,
    required this.syncStatus,
  });

  final String id;
  final Identification identification;
  final MissingPerson missing;
  final Operation operation;
  final String physicalDescription;
  final String clothing;
  final String health;
  final String procedures;
  final List<String> teams;
  final List<String> resources;
  final String conclusion;
  final List<String> attachments;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  String get title => identification.title;
  String get location => operation.location;

  Report copyWith({SyncStatus? syncStatus}) => Report(
        id: id,
        identification: identification,
        missing: missing,
        operation: operation,
        physicalDescription: physicalDescription,
        clothing: clothing,
        health: health,
        procedures: procedures,
        teams: teams,
        resources: resources,
        conclusion: conclusion,
        attachments: attachments,
        updatedAt: updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'identification': identification.toJson(),
        'missing': missing.toJson(),
        'operation': operation.toJson(),
        'physicalDescription': physicalDescription,
        'clothing': clothing,
        'health': health,
        'procedures': procedures,
        'teams': teams,
        'resources': resources,
        'conclusion': conclusion,
        'attachments': attachments,
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.name,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        identification: Identification.fromJson(
          Map<String, dynamic>.from(json['identification'] as Map),
        ),
        missing: MissingPerson.fromJson(Map<String, dynamic>.from(json['missing'] as Map)),
        operation: Operation.fromJson(Map<String, dynamic>.from(json['operation'] as Map)),
        physicalDescription: json['physicalDescription'] as String? ?? '',
        clothing: json['clothing'] as String? ?? '',
        health: json['health'] as String? ?? '',
        procedures: json['procedures'] as String? ?? '',
        teams: List<String>.from(json['teams'] as List? ?? const []),
        resources: List<String>.from(json['resources'] as List? ?? const []),
        conclusion: json['conclusion'] as String? ?? '',
        attachments: List<String>.from(json['attachments'] as List? ?? const []),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        syncStatus: SyncStatus.values.firstWhere(
          (value) => value.name == json['syncStatus'],
          orElse: () => SyncStatus.pending,
        ),
      );
}

enum SyncStatus { pending, synced }

class Identification {
  const Identification({required this.title, required this.date, required this.coordinator});
  final String title;
  final DateTime date;
  final String coordinator;
  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
        'coordinator': coordinator,
      };
  factory Identification.fromJson(Map<String, dynamic> json) => Identification(
        title: json['title'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        coordinator: json['coordinator'] as String? ?? '',
      );
}

class MissingPerson {
  const MissingPerson({required this.name, required this.lastSeen, required this.contact});
  final String name;
  final String lastSeen;
  final String contact;
  Map<String, dynamic> toJson() => {'name': name, 'lastSeen': lastSeen, 'contact': contact};
  factory MissingPerson.fromJson(Map<String, dynamic> json) => MissingPerson(
        name: json['name'] as String? ?? '',
        lastSeen: json['lastSeen'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
      );
}

class Operation {
  const Operation({required this.location, required this.start, required this.end});
  final String location;
  final String start;
  final String end;
  Map<String, dynamic> toJson() => {'location': location, 'start': start, 'end': end};
  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
        location: json['location'] as String? ?? '',
        start: json['start'] as String? ?? '',
        end: json['end'] as String? ?? '',
      );
}
