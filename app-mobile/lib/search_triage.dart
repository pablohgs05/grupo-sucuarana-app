enum AnswerState { unknown, yes, no }

AnswerState _answerState(dynamic value) => AnswerState.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AnswerState.unknown,
    );

String _text(Map<String, dynamic> json, String key) =>
    json[key] as String? ?? '';

class SearchTriage {
  const SearchTriage({
    required this.metadata,
    required this.person,
    required this.relatedPeople,
    required this.historyAndDestination,
    required this.transportation,
    required this.lastSeen,
    required this.physicalDescription,
    required this.clothingAndAccessories,
    required this.personalSupplies,
    required this.healthAndBehavior,
    required this.experienceAndResistance,
    required this.previousActions,
  });

  static const empty = SearchTriage(
    metadata: TriageMetadata.empty,
    person: PersonIdentification.empty,
    relatedPeople: <RelatedPerson>[],
    historyAndDestination: HistoryAndDestination.empty,
    transportation: Transportation.empty,
    lastSeen: LastSeen.empty,
    physicalDescription: PhysicalDescription.empty,
    clothingAndAccessories: ClothingAndAccessories.empty,
    personalSupplies: PersonalSupplies.empty,
    healthAndBehavior: HealthAndBehavior.empty,
    experienceAndResistance: ExperienceAndResistance.empty,
    previousActions: PreviousActions.empty,
  );

  final TriageMetadata metadata;
  final PersonIdentification person;
  final List<RelatedPerson> relatedPeople;
  final HistoryAndDestination historyAndDestination;
  final Transportation transportation;
  final LastSeen lastSeen;
  final PhysicalDescription physicalDescription;
  final ClothingAndAccessories clothingAndAccessories;
  final PersonalSupplies personalSupplies;
  final HealthAndBehavior healthAndBehavior;
  final ExperienceAndResistance experienceAndResistance;
  final PreviousActions previousActions;

  factory SearchTriage.fromLegacy({
    required String name,
    required String lastSeen,
    required String contact,
    required String physicalDescription,
    required String clothing,
    required String health,
    required String procedures,
  }) =>
      SearchTriage(
        metadata: TriageMetadata.empty,
        person: PersonIdentification(
          name: name,
          nickname: '',
          address: '',
          contacts: const <String>[],
          additionalAddresses: const <String>[],
          referenceContact: contact,
        ),
        relatedPeople: const <RelatedPerson>[],
        historyAndDestination: HistoryAndDestination.empty,
        transportation: Transportation.empty,
        lastSeen: LastSeen(
          when: '',
          where: '',
          intendedDirection: '',
          witnessName: '',
          witnessAddress: '',
          witnessContact: '',
          notes: lastSeen,
        ),
        physicalDescription: PhysicalDescription(
          age: '',
          color: '',
          height: '',
          hair: '',
          beard: AnswerState.unknown,
          notes: physicalDescription,
        ),
        clothingAndAccessories: ClothingAndAccessories(
          items: const <ClothingItem>[],
          notes: clothing,
        ),
        personalSupplies: PersonalSupplies.empty,
        healthAndBehavior: HealthAndBehavior(
          generalCondition: '',
          physicalDisabilities: '',
          diseases: '',
          psychologicalIssues: '',
          medicationUse: AnswerState.unknown,
          medicationDetails: '',
          tookMedication: AnswerState.unknown,
          lackOfMedicationConsequences: '',
          drugUse: AnswerState.unknown,
          drugDetails: '',
          familyConflicts: AnswerState.unknown,
          workConflict: AnswerState.unknown,
          financialProblems: AnswerState.unknown,
          previousSelfHarmAttempt: AnswerState.unknown,
          previousSelfHarmDetails: '',
          previousSelfHarmThreat: AnswerState.unknown,
          previousSelfHarmThreatDetails: '',
          notes: health,
        ),
        experienceAndResistance: ExperienceAndResistance.empty,
        previousActions: PreviousActions(description: procedures),
      );

  SearchTriage mergeLegacy({
    String? name,
    String? lastSeen,
    String? contact,
    String? physicalDescription,
    String? clothing,
    String? health,
    String? procedures,
  }) =>
      SearchTriage(
        metadata: metadata,
        person: name == null && contact == null
            ? person
            : person.copyWith(name: name, referenceContact: contact),
        relatedPeople: relatedPeople,
        historyAndDestination: historyAndDestination,
        transportation: transportation,
        lastSeen: lastSeen == null
            ? this.lastSeen
            : this.lastSeen.copyWith(notes: lastSeen),
        physicalDescription: physicalDescription == null
            ? this.physicalDescription
            : this.physicalDescription.copyWith(notes: physicalDescription),
        clothingAndAccessories: clothing == null
            ? clothingAndAccessories
            : clothingAndAccessories.copyWith(notes: clothing),
        personalSupplies: personalSupplies,
        healthAndBehavior: health == null
            ? healthAndBehavior
            : healthAndBehavior.copyWith(notes: health),
        experienceAndResistance: experienceAndResistance,
        previousActions: procedures == null
            ? previousActions
            : previousActions.copyWith(description: procedures),
      );

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'person': person.toJson(),
        'relatedPeople': relatedPeople.map((item) => item.toJson()).toList(),
        'historyAndDestination': historyAndDestination.toJson(),
        'transportation': transportation.toJson(),
        'lastSeen': lastSeen.toJson(),
        'physicalDescription': physicalDescription.toJson(),
        'clothingAndAccessories': clothingAndAccessories.toJson(),
        'personalSupplies': personalSupplies.toJson(),
        'healthAndBehavior': healthAndBehavior.toJson(),
        'experienceAndResistance': experienceAndResistance.toJson(),
        'previousActions': previousActions.toJson(),
      };

  factory SearchTriage.fromJson(Map<String, dynamic> json) => SearchTriage(
        metadata: TriageMetadata.fromJson(
          Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
        ),
        person: PersonIdentification.fromJson(
          Map<String, dynamic>.from(json['person'] as Map? ?? const {}),
        ),
        relatedPeople: (json['relatedPeople'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => RelatedPerson.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        historyAndDestination: HistoryAndDestination.fromJson(
          Map<String, dynamic>.from(
            json['historyAndDestination'] as Map? ?? const {},
          ),
        ),
        transportation: Transportation.fromJson(
          Map<String, dynamic>.from(
            json['transportation'] as Map? ?? const {},
          ),
        ),
        lastSeen: LastSeen.fromJson(
          Map<String, dynamic>.from(json['lastSeen'] as Map? ?? const {}),
        ),
        physicalDescription: PhysicalDescription.fromJson(
          Map<String, dynamic>.from(
            json['physicalDescription'] as Map? ?? const {},
          ),
        ),
        clothingAndAccessories: ClothingAndAccessories.fromJson(
          Map<String, dynamic>.from(
            json['clothingAndAccessories'] as Map? ?? const {},
          ),
        ),
        personalSupplies: PersonalSupplies.fromJson(
          Map<String, dynamic>.from(
            json['personalSupplies'] as Map? ?? const {},
          ),
        ),
        healthAndBehavior: HealthAndBehavior.fromJson(
          Map<String, dynamic>.from(
            json['healthAndBehavior'] as Map? ?? const {},
          ),
        ),
        experienceAndResistance: ExperienceAndResistance.fromJson(
          Map<String, dynamic>.from(
            json['experienceAndResistance'] as Map? ?? const {},
          ),
        ),
        previousActions: PreviousActions.fromJson(
          Map<String, dynamic>.from(
            json['previousActions'] as Map? ?? const {},
          ),
        ),
      );
}

class TriageMetadata {
  const TriageMetadata({
    required this.formNumber,
    required this.factDate,
    required this.factTime,
    required this.noticeDate,
    required this.noticeTime,
  });

  static const empty = TriageMetadata(
    formNumber: '',
    factDate: '',
    factTime: '',
    noticeDate: '',
    noticeTime: '',
  );

  final String formNumber;
  final String factDate;
  final String factTime;
  final String noticeDate;
  final String noticeTime;

  Map<String, dynamic> toJson() => {
        'formNumber': formNumber,
        'factDate': factDate,
        'factTime': factTime,
        'noticeDate': noticeDate,
        'noticeTime': noticeTime,
      };

  factory TriageMetadata.fromJson(Map<String, dynamic> json) => TriageMetadata(
        formNumber: _text(json, 'formNumber'),
        factDate: _text(json, 'factDate'),
        factTime: _text(json, 'factTime'),
        noticeDate: _text(json, 'noticeDate'),
        noticeTime: _text(json, 'noticeTime'),
      );
}

class PersonIdentification {
  const PersonIdentification({
    required this.name,
    required this.nickname,
    required this.address,
    required this.contacts,
    required this.additionalAddresses,
    required this.referenceContact,
  });

  static const empty = PersonIdentification(
    name: '',
    nickname: '',
    address: '',
    contacts: <String>[],
    additionalAddresses: <String>[],
    referenceContact: '',
  );

  final String name;
  final String nickname;
  final String address;
  final List<String> contacts;
  final List<String> additionalAddresses;
  final String referenceContact;

  PersonIdentification copyWith({
    String? name,
    String? referenceContact,
  }) =>
      PersonIdentification(
        name: name ?? this.name,
        nickname: nickname,
        address: address,
        contacts: contacts,
        additionalAddresses: additionalAddresses,
        referenceContact: referenceContact ?? this.referenceContact,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'nickname': nickname,
        'address': address,
        'contacts': contacts,
        'additionalAddresses': additionalAddresses,
        'referenceContact': referenceContact,
      };

  factory PersonIdentification.fromJson(Map<String, dynamic> json) =>
      PersonIdentification(
        name: _text(json, 'name'),
        nickname: _text(json, 'nickname'),
        address: _text(json, 'address'),
        contacts: List<String>.from(
          json['contacts'] as List? ?? const [],
        ),
        additionalAddresses: List<String>.from(
          json['additionalAddresses'] as List? ?? const [],
        ),
        referenceContact: _text(json, 'referenceContact'),
      );
}

class RelatedPerson {
  const RelatedPerson({
    required this.relation,
    required this.name,
    required this.contact,
  });

  final String relation;
  final String name;
  final String contact;

  Map<String, dynamic> toJson() => {
        'relation': relation,
        'name': name,
        'contact': contact,
      };

  factory RelatedPerson.fromJson(Map<String, dynamic> json) => RelatedPerson(
        relation: _text(json, 'relation'),
        name: _text(json, 'name'),
        contact: _text(json, 'contact'),
      );
}

class HistoryAndDestination {
  const HistoryAndDestination({
    required this.narrative,
    required this.recurringMotivation,
    required this.intendedDestination,
  });

  static const empty = HistoryAndDestination(
    narrative: '',
    recurringMotivation: AnswerState.unknown,
    intendedDestination: '',
  );

  final String narrative;
  final AnswerState recurringMotivation;
  final String intendedDestination;

  Map<String, dynamic> toJson() => {
        'narrative': narrative,
        'recurringMotivation': recurringMotivation.name,
        'intendedDestination': intendedDestination,
      };

  factory HistoryAndDestination.fromJson(Map<String, dynamic> json) =>
      HistoryAndDestination(
        narrative: _text(json, 'narrative'),
        recurringMotivation: _answerState(json['recurringMotivation']),
        intendedDestination: _text(json, 'intendedDestination'),
      );
}

class Transportation {
  const Transportation({
    required this.onFoot,
    required this.bicycle,
    required this.bicycleMakeModel,
    required this.bicycleColor,
    required this.bicycleSize,
    required this.motorVehicle,
    required this.motorVehicleType,
    required this.motorVehicleMakeModel,
    required this.motorVehicleColor,
    required this.motorVehiclePlate,
    required this.mount,
    required this.mountType,
    required this.mountColor,
    required this.vehicleOrMountFound,
    required this.vehicleOrMountFoundDetails,
    required this.mountReturned,
    required this.mountReturnDetails,
  });

  static const empty = Transportation(
    onFoot: AnswerState.unknown,
    bicycle: AnswerState.unknown,
    bicycleMakeModel: '',
    bicycleColor: '',
    bicycleSize: '',
    motorVehicle: AnswerState.unknown,
    motorVehicleType: '',
    motorVehicleMakeModel: '',
    motorVehicleColor: '',
    motorVehiclePlate: '',
    mount: AnswerState.unknown,
    mountType: '',
    mountColor: '',
    vehicleOrMountFound: AnswerState.unknown,
    vehicleOrMountFoundDetails: '',
    mountReturned: AnswerState.unknown,
    mountReturnDetails: '',
  );

  final AnswerState onFoot;
  final AnswerState bicycle;
  final String bicycleMakeModel;
  final String bicycleColor;
  final String bicycleSize;
  final AnswerState motorVehicle;
  final String motorVehicleType;
  final String motorVehicleMakeModel;
  final String motorVehicleColor;
  final String motorVehiclePlate;
  final AnswerState mount;
  final String mountType;
  final String mountColor;
  final AnswerState vehicleOrMountFound;
  final String vehicleOrMountFoundDetails;
  final AnswerState mountReturned;
  final String mountReturnDetails;

  Map<String, dynamic> toJson() => {
        'onFoot': onFoot.name,
        'bicycle': bicycle.name,
        'bicycleMakeModel': bicycleMakeModel,
        'bicycleColor': bicycleColor,
        'bicycleSize': bicycleSize,
        'motorVehicle': motorVehicle.name,
        'motorVehicleType': motorVehicleType,
        'motorVehicleMakeModel': motorVehicleMakeModel,
        'motorVehicleColor': motorVehicleColor,
        'motorVehiclePlate': motorVehiclePlate,
        'mount': mount.name,
        'mountType': mountType,
        'mountColor': mountColor,
        'vehicleOrMountFound': vehicleOrMountFound.name,
        'vehicleOrMountFoundDetails': vehicleOrMountFoundDetails,
        'mountReturned': mountReturned.name,
        'mountReturnDetails': mountReturnDetails,
      };

  factory Transportation.fromJson(Map<String, dynamic> json) => Transportation(
        onFoot: _answerState(json['onFoot']),
        bicycle: _answerState(json['bicycle']),
        bicycleMakeModel: _text(json, 'bicycleMakeModel'),
        bicycleColor: _text(json, 'bicycleColor'),
        bicycleSize: _text(json, 'bicycleSize'),
        motorVehicle: _answerState(json['motorVehicle']),
        motorVehicleType: _text(json, 'motorVehicleType'),
        motorVehicleMakeModel: _text(json, 'motorVehicleMakeModel'),
        motorVehicleColor: _text(json, 'motorVehicleColor'),
        motorVehiclePlate: _text(json, 'motorVehiclePlate'),
        mount: _answerState(json['mount']),
        mountType: _text(json, 'mountType'),
        mountColor: _text(json, 'mountColor'),
        vehicleOrMountFound: _answerState(json['vehicleOrMountFound']),
        vehicleOrMountFoundDetails:
            _text(json, 'vehicleOrMountFoundDetails'),
        mountReturned: _answerState(json['mountReturned']),
        mountReturnDetails: _text(json, 'mountReturnDetails'),
      );
}

class LastSeen {
  const LastSeen({
    required this.when,
    required this.where,
    required this.intendedDirection,
    required this.witnessName,
    required this.witnessAddress,
    required this.witnessContact,
    required this.notes,
  });

  static const empty = LastSeen(
    when: '',
    where: '',
    intendedDirection: '',
    witnessName: '',
    witnessAddress: '',
    witnessContact: '',
    notes: '',
  );

  final String when;
  final String where;
  final String intendedDirection;
  final String witnessName;
  final String witnessAddress;
  final String witnessContact;
  final String notes;

  String get legacySummary => notes.isNotEmpty ? notes : where;

  LastSeen copyWith({String? notes}) => LastSeen(
        when: when,
        where: where,
        intendedDirection: intendedDirection,
        witnessName: witnessName,
        witnessAddress: witnessAddress,
        witnessContact: witnessContact,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'when': when,
        'where': where,
        'intendedDirection': intendedDirection,
        'witnessName': witnessName,
        'witnessAddress': witnessAddress,
        'witnessContact': witnessContact,
        'notes': notes,
      };

  factory LastSeen.fromJson(Map<String, dynamic> json) => LastSeen(
        when: _text(json, 'when'),
        where: _text(json, 'where'),
        intendedDirection: _text(json, 'intendedDirection'),
        witnessName: _text(json, 'witnessName'),
        witnessAddress: _text(json, 'witnessAddress'),
        witnessContact: _text(json, 'witnessContact'),
        notes: _text(json, 'notes'),
      );
}

class PhysicalDescription {
  const PhysicalDescription({
    required this.age,
    required this.color,
    required this.height,
    required this.hair,
    required this.beard,
    required this.notes,
  });

  static const empty = PhysicalDescription(
    age: '',
    color: '',
    height: '',
    hair: '',
    beard: AnswerState.unknown,
    notes: '',
  );

  final String age;
  final String color;
  final String height;
  final String hair;
  final AnswerState beard;
  final String notes;

  String get legacySummary {
    if (notes.isNotEmpty) return notes;
    final values = <String>[
      if (age.isNotEmpty) 'Idade: $age',
      if (color.isNotEmpty) 'Cor: $color',
      if (height.isNotEmpty) 'Altura: $height',
      if (hair.isNotEmpty) 'Cabelos: $hair',
    ];
    return values.join(' • ');
  }

  PhysicalDescription copyWith({String? notes}) => PhysicalDescription(
        age: age,
        color: color,
        height: height,
        hair: hair,
        beard: beard,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'age': age,
        'color': color,
        'height': height,
        'hair': hair,
        'beard': beard.name,
        'notes': notes,
      };

  factory PhysicalDescription.fromJson(Map<String, dynamic> json) =>
      PhysicalDescription(
        age: _text(json, 'age'),
        color: _text(json, 'color'),
        height: _text(json, 'height'),
        hair: _text(json, 'hair'),
        beard: _answerState(json['beard']),
        notes: _text(json, 'notes'),
      );
}

class ClothingAndAccessories {
  const ClothingAndAccessories({
    required this.items,
    required this.notes,
  });

  static const empty = ClothingAndAccessories(
    items: <ClothingItem>[],
    notes: '',
  );

  final List<ClothingItem> items;
  final String notes;

  String get legacySummary {
    if (notes.isNotEmpty) return notes;
    return items
        .map((item) => item.item)
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  ClothingAndAccessories copyWith({String? notes}) => ClothingAndAccessories(
        items: items,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'notes': notes,
      };

  factory ClothingAndAccessories.fromJson(Map<String, dynamic> json) =>
      ClothingAndAccessories(
        items: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => ClothingItem.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        notes: _text(json, 'notes'),
      );
}

class ClothingItem {
  const ClothingItem({
    required this.item,
    required this.type,
    required this.color,
    required this.materialOrPattern,
    required this.size,
    required this.model,
  });

  final String item;
  final String type;
  final String color;
  final String materialOrPattern;
  final String size;
  final String model;

  Map<String, dynamic> toJson() => {
        'item': item,
        'type': type,
        'color': color,
        'materialOrPattern': materialOrPattern,
        'size': size,
        'model': model,
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        item: _text(json, 'item'),
        type: _text(json, 'type'),
        color: _text(json, 'color'),
        materialOrPattern: _text(json, 'materialOrPattern'),
        size: _text(json, 'size'),
        model: _text(json, 'model'),
      );
}

class PersonalSupplies {
  const PersonalSupplies({required this.notes});

  static const empty = PersonalSupplies(notes: '');

  final String notes;

  Map<String, dynamic> toJson() => {'notes': notes};

  factory PersonalSupplies.fromJson(Map<String, dynamic> json) =>
      PersonalSupplies(notes: _text(json, 'notes'));
}

class HealthAndBehavior {
  const HealthAndBehavior({
    required this.generalCondition,
    required this.physicalDisabilities,
    required this.diseases,
    required this.psychologicalIssues,
    required this.medicationUse,
    required this.medicationDetails,
    required this.tookMedication,
    required this.lackOfMedicationConsequences,
    required this.drugUse,
    required this.drugDetails,
    required this.familyConflicts,
    required this.workConflict,
    required this.financialProblems,
    required this.previousSelfHarmAttempt,
    required this.previousSelfHarmDetails,
    required this.previousSelfHarmThreat,
    required this.previousSelfHarmThreatDetails,
    required this.notes,
  });

  static const empty = HealthAndBehavior(
    generalCondition: '',
    physicalDisabilities: '',
    diseases: '',
    psychologicalIssues: '',
    medicationUse: AnswerState.unknown,
    medicationDetails: '',
    tookMedication: AnswerState.unknown,
    lackOfMedicationConsequences: '',
    drugUse: AnswerState.unknown,
    drugDetails: '',
    familyConflicts: AnswerState.unknown,
    workConflict: AnswerState.unknown,
    financialProblems: AnswerState.unknown,
    previousSelfHarmAttempt: AnswerState.unknown,
    previousSelfHarmDetails: '',
    previousSelfHarmThreat: AnswerState.unknown,
    previousSelfHarmThreatDetails: '',
    notes: '',
  );

  final String generalCondition;
  final String physicalDisabilities;
  final String diseases;
  final String psychologicalIssues;
  final AnswerState medicationUse;
  final String medicationDetails;
  final AnswerState tookMedication;
  final String lackOfMedicationConsequences;
  final AnswerState drugUse;
  final String drugDetails;
  final AnswerState familyConflicts;
  final AnswerState workConflict;
  final AnswerState financialProblems;
  final AnswerState previousSelfHarmAttempt;
  final String previousSelfHarmDetails;
  final AnswerState previousSelfHarmThreat;
  final String previousSelfHarmThreatDetails;
  final String notes;

  String get legacySummary {
    if (notes.isNotEmpty) return notes;
    final values = <String>[
      if (generalCondition.isNotEmpty) generalCondition,
      if (physicalDisabilities.isNotEmpty)
        'Deficiências: $physicalDisabilities',
      if (diseases.isNotEmpty) 'Doenças: $diseases',
      if (psychologicalIssues.isNotEmpty)
        'Questões psicológicas: $psychologicalIssues',
    ];
    return values.join(' • ');
  }

  HealthAndBehavior copyWith({String? notes}) => HealthAndBehavior(
        generalCondition: generalCondition,
        physicalDisabilities: physicalDisabilities,
        diseases: diseases,
        psychologicalIssues: psychologicalIssues,
        medicationUse: medicationUse,
        medicationDetails: medicationDetails,
        tookMedication: tookMedication,
        lackOfMedicationConsequences: lackOfMedicationConsequences,
        drugUse: drugUse,
        drugDetails: drugDetails,
        familyConflicts: familyConflicts,
        workConflict: workConflict,
        financialProblems: financialProblems,
        previousSelfHarmAttempt: previousSelfHarmAttempt,
        previousSelfHarmDetails: previousSelfHarmDetails,
        previousSelfHarmThreat: previousSelfHarmThreat,
        previousSelfHarmThreatDetails: previousSelfHarmThreatDetails,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'generalCondition': generalCondition,
        'physicalDisabilities': physicalDisabilities,
        'diseases': diseases,
        'psychologicalIssues': psychologicalIssues,
        'medicationUse': medicationUse.name,
        'medicationDetails': medicationDetails,
        'tookMedication': tookMedication.name,
        'lackOfMedicationConsequences': lackOfMedicationConsequences,
        'drugUse': drugUse.name,
        'drugDetails': drugDetails,
        'familyConflicts': familyConflicts.name,
        'workConflict': workConflict.name,
        'financialProblems': financialProblems.name,
        'previousSelfHarmAttempt': previousSelfHarmAttempt.name,
        'previousSelfHarmDetails': previousSelfHarmDetails,
        'previousSelfHarmThreat': previousSelfHarmThreat.name,
        'previousSelfHarmThreatDetails': previousSelfHarmThreatDetails,
        'notes': notes,
      };

  factory HealthAndBehavior.fromJson(Map<String, dynamic> json) =>
      HealthAndBehavior(
        generalCondition: _text(json, 'generalCondition'),
        physicalDisabilities: _text(json, 'physicalDisabilities'),
        diseases: _text(json, 'diseases'),
        psychologicalIssues: _text(json, 'psychologicalIssues'),
        medicationUse: _answerState(json['medicationUse']),
        medicationDetails: _text(json, 'medicationDetails'),
        tookMedication: _answerState(json['tookMedication']),
        lackOfMedicationConsequences:
            _text(json, 'lackOfMedicationConsequences'),
        drugUse: _answerState(json['drugUse']),
        drugDetails: _text(json, 'drugDetails'),
        familyConflicts: _answerState(json['familyConflicts']),
        workConflict: _answerState(json['workConflict']),
        financialProblems: _answerState(json['financialProblems']),
        previousSelfHarmAttempt:
            _answerState(json['previousSelfHarmAttempt']),
        previousSelfHarmDetails: _text(json, 'previousSelfHarmDetails'),
        previousSelfHarmThreat: _answerState(json['previousSelfHarmThreat']),
        previousSelfHarmThreatDetails:
            _text(json, 'previousSelfHarmThreatDetails'),
        notes: _text(json, 'notes'),
      );
}

class ExperienceAndResistance {
  const ExperienceAndResistance({
    required this.ruralWalking,
    required this.ruralWalkingDetails,
    required this.knowsArea,
    required this.knowsAreaSince,
    required this.previouslyLost,
    required this.previousLostDetails,
    required this.physicalResistance,
    required this.canSwim,
  });

  static const empty = ExperienceAndResistance(
    ruralWalking: AnswerState.unknown,
    ruralWalkingDetails: '',
    knowsArea: AnswerState.unknown,
    knowsAreaSince: '',
    previouslyLost: AnswerState.unknown,
    previousLostDetails: '',
    physicalResistance: '',
    canSwim: AnswerState.unknown,
  );

  final AnswerState ruralWalking;
  final String ruralWalkingDetails;
  final AnswerState knowsArea;
  final String knowsAreaSince;
  final AnswerState previouslyLost;
  final String previousLostDetails;
  final String physicalResistance;
  final AnswerState canSwim;

  Map<String, dynamic> toJson() => {
        'ruralWalking': ruralWalking.name,
        'ruralWalkingDetails': ruralWalkingDetails,
        'knowsArea': knowsArea.name,
        'knowsAreaSince': knowsAreaSince,
        'previouslyLost': previouslyLost.name,
        'previousLostDetails': previousLostDetails,
        'physicalResistance': physicalResistance,
        'canSwim': canSwim.name,
      };

  factory ExperienceAndResistance.fromJson(Map<String, dynamic> json) =>
      ExperienceAndResistance(
        ruralWalking: _answerState(json['ruralWalking']),
        ruralWalkingDetails: _text(json, 'ruralWalkingDetails'),
        knowsArea: _answerState(json['knowsArea']),
        knowsAreaSince: _text(json, 'knowsAreaSince'),
        previouslyLost: _answerState(json['previouslyLost']),
        previousLostDetails: _text(json, 'previousLostDetails'),
        physicalResistance: _text(json, 'physicalResistance'),
        canSwim: _answerState(json['canSwim']),
      );
}

class PreviousActions {
  const PreviousActions({required this.description});

  static const empty = PreviousActions(description: '');

  final String description;

  PreviousActions copyWith({String? description}) =>
      PreviousActions(description: description ?? this.description);

  Map<String, dynamic> toJson() => {'description': description};

  factory PreviousActions.fromJson(Map<String, dynamic> json) =>
      PreviousActions(description: _text(json, 'description'));
}
