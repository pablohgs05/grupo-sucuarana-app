import 'operational_report.dart';
import 'report_attachment.dart';
import 'search_triage.dart';

class Report {
  Report({
    required this.id,
    required this.identification,
    SearchTriage? searchTriage,
    MissingPerson? missing,
    required this.operation,
    OperationalReportContent? operationalContent,
    String? physicalDescription,
    String? clothing,
    String? health,
    String? procedures,
    List<String>? teams,
    List<String>? resources,
    String? conclusion,
    List<String>? attachments,
    List<ReportAttachment>? attachmentItems,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.lastEditedStep,
    this.lastEditedSection,
    required this.syncStatus,
  }) : searchTriage = searchTriage == null
            ? SearchTriage.fromLegacy(
                name: missing?.name ?? '',
                lastSeen: missing?.lastSeen ?? '',
                contact: missing?.contact ?? '',
                physicalDescription: physicalDescription ?? '',
                clothing: clothing ?? '',
                health: health ?? '',
                procedures: procedures ?? '',
              )
            : searchTriage.mergeLegacy(
                name: missing?.name,
                lastSeen: missing?.lastSeen,
                contact: missing?.contact,
                physicalDescription: physicalDescription,
                clothing: clothing,
                health: health,
                procedures: procedures,
              ),
        operationalContent = operationalContent ??
            OperationalReportContent.fromLegacy(
              teams: teams ?? const <String>[],
              resources: resources ?? const <String>[],
              conclusion: conclusion ?? '',
            ),
        attachmentItems = attachmentItems ??
            (attachments ?? const <String>[])
                .asMap()
                .entries
                .map(
                  (entry) => ReportAttachment.fromLegacyPath(
                    entry.value,
                    entry.key,
                  ),
                )
                .toList(growable: false);

  final String id;
  final Identification identification;
  final SearchTriage searchTriage;
  final Operation operation;
  final OperationalReportContent operationalContent;
  final List<ReportAttachment> attachmentItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportLifecycle lifecycle;
  final int lastEditedStep;
  final String? lastEditedSection;
  final SyncStatus syncStatus;

  String get title => identification.title;
  String get location => operation.location;
  List<String> get teams => operationalContent.teams
      .map((team) => team.legacySummary)
      .toList(growable: false);
  List<String> get resources => operationalContent.resources
      .map((resource) => resource.legacySummary)
      .toList(growable: false);
  String get conclusion => operationalContent.conclusion;
  List<String> get attachments => attachmentItems
      .map((attachment) => attachment.localPath)
      .toList(growable: false);

  // Temporary compatibility accessors until M4 migrates the form UI to the
  // structured triage fields. SearchTriage remains the single source of truth.
  MissingPerson get missing => MissingPerson(
        name: searchTriage.person.name,
        lastSeen: searchTriage.lastSeen.legacySummary,
        contact: searchTriage.person.referenceContact,
      );

  String get physicalDescription =>
      searchTriage.physicalDescription.legacySummary;
  String get clothing => searchTriage.clothingAndAccessories.legacySummary;
  String get health => searchTriage.healthAndBehavior.legacySummary;
  String get procedures => searchTriage.previousActions.description;

  Report copyWith({
    OperationalReportContent? operationalContent,
    List<ReportAttachment>? attachmentItems,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReportLifecycle? lifecycle,
    int? lastEditedStep,
    String? lastEditedSection,
    SyncStatus? syncStatus,
  }) =>
      Report(
        id: id,
        identification: identification,
        searchTriage: searchTriage,
        operation: operation,
        operationalContent: operationalContent ?? this.operationalContent,
        attachmentItems: attachmentItems ?? this.attachmentItems,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lifecycle: lifecycle ?? this.lifecycle,
        lastEditedStep: lastEditedStep ?? this.lastEditedStep,
        lastEditedSection: lastEditedSection ?? this.lastEditedSection,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'identification': identification.toJson(),
        'searchTriage': searchTriage.toJson(),
        'operation': operation.toJson(),
        'operationalContent': operationalContent.toJson(),

        // Transitional mirrors are derived from SearchTriage so older
        // consumers can keep reading the payload during the M3 -> M4 bridge.
        'missing': missing.toJson(),
        'physicalDescription': physicalDescription,
        'clothing': clothing,
        'health': health,
        'procedures': procedures,
        'teams': teams,
        'resources': resources,
        'conclusion': conclusion,
        'attachmentItems':
            attachmentItems.map((attachment) => attachment.toJson()).toList(),
        'attachments': attachments,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lifecycle': lifecycle.name,
        'lastEditedStep': lastEditedStep,
        'lastEditedSection': lastEditedSection,
        'syncStatus': syncStatus.name,
      };

  factory Report.fromJson(Map<String, dynamic> json) {
    final updatedAt = DateTime.parse(json['updatedAt'] as String);
    final createdAtValue = json['createdAt'] as String?;
    final lifecycleValue = json['lifecycle'] as String?;
    final searchTriageValue = json['searchTriage'];
    final operationalContentValue = json['operationalContent'];
    final attachmentItemsValue = json['attachmentItems'];

    final attachmentItems = attachmentItemsValue is List
        ? attachmentItemsValue
            .whereType<Map>()
            .map(
              (item) => ReportAttachment.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : List<String>.from(json['attachments'] as List? ?? const [])
            .asMap()
            .entries
            .map(
              (entry) => ReportAttachment.fromLegacyPath(
                entry.value,
                entry.key,
              ),
            )
            .toList(growable: false);

    final operationalContent = operationalContentValue is Map
        ? OperationalReportContent.fromJson(
            Map<String, dynamic>.from(operationalContentValue),
          )
        : OperationalReportContent.fromLegacy(
            teams: List<String>.from(json['teams'] as List? ?? const []),
            resources:
                List<String>.from(json['resources'] as List? ?? const []),
            conclusion: json['conclusion'] as String? ?? '',
          );

    final common = (
      id: json['id'] as String,
      identification: Identification.fromJson(
        Map<String, dynamic>.from(json['identification'] as Map),
      ),
      operation: Operation.fromJson(
        Map<String, dynamic>.from(json['operation'] as Map),
      ),
      operationalContent: operationalContent,
      attachmentItems: attachmentItems,
      createdAt: createdAtValue == null
          ? updatedAt
          : DateTime.tryParse(createdAtValue) ?? updatedAt,
      updatedAt: updatedAt,
      lifecycle: ReportLifecycle.values.firstWhere(
        (value) => value.name == lifecycleValue,
        orElse: () => ReportLifecycle.readyForReview,
      ),
      lastEditedStep: (json['lastEditedStep'] as num?)?.toInt() ?? 0,
      lastEditedSection: json['lastEditedSection'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (value) => value.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
    );

    if (searchTriageValue is Map) {
      return Report(
        id: common.id,
        identification: common.identification,
        searchTriage: SearchTriage.fromJson(
          Map<String, dynamic>.from(searchTriageValue),
        ),
        operation: common.operation,
        operationalContent: common.operationalContent,
        attachmentItems: common.attachmentItems,
        createdAt: common.createdAt,
        updatedAt: common.updatedAt,
        lifecycle: common.lifecycle,
        lastEditedStep: common.lastEditedStep,
        lastEditedSection: common.lastEditedSection,
        syncStatus: common.syncStatus,
      );
    }

    final missingValue = json['missing'];
    return Report(
      id: common.id,
      identification: common.identification,
      missing: missingValue is Map
          ? MissingPerson.fromJson(Map<String, dynamic>.from(missingValue))
          : MissingPerson.empty,
      operation: common.operation,
      operationalContent: common.operationalContent,
      physicalDescription: json['physicalDescription'] as String? ?? '',
      clothing: json['clothing'] as String? ?? '',
      health: json['health'] as String? ?? '',
      procedures: json['procedures'] as String? ?? '',
      attachmentItems: common.attachmentItems,
      createdAt: common.createdAt,
      updatedAt: common.updatedAt,
      lifecycle: common.lifecycle,
      lastEditedStep: common.lastEditedStep,
      lastEditedSection: common.lastEditedSection,
      syncStatus: common.syncStatus,
    );
  }
}

enum ReportLifecycle { draft, readyForReview, finalized, exported }

enum SyncStatus { pending, synced }

class Identification {
  const Identification({
    required this.title,
    required this.date,
    required this.coordinator,
  });

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
  const MissingPerson({
    required this.name,
    required this.lastSeen,
    required this.contact,
  });

  static const empty = MissingPerson(name: '', lastSeen: '', contact: '');

  final String name;
  final String lastSeen;
  final String contact;

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastSeen': lastSeen,
        'contact': contact,
      };

  factory MissingPerson.fromJson(Map<String, dynamic> json) => MissingPerson(
        name: json['name'] as String? ?? '',
        lastSeen: json['lastSeen'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
      );
}

class Operation {
  const Operation({
    required this.location,
    required this.start,
    required this.end,
  });

  final String location;
  final String start;
  final String end;

  Map<String, dynamic> toJson() => {
        'location': location,
        'start': start,
        'end': end,
      };

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
        location: json['location'] as String? ?? '',
        start: json['start'] as String? ?? '',
        end: json['end'] as String? ?? '',
      );
}
