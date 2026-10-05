class ReportAttachment {
  const ReportAttachment({
    required this.id,
    required this.localPath,
    required this.originalName,
    required this.caption,
    required this.managedLocalFile,
  });

  final String id;
  final String localPath;
  final String originalName;
  final String caption;
  final bool managedLocalFile;

  ReportAttachment copyWith({
    String? id,
    String? localPath,
    String? originalName,
    String? caption,
    bool? managedLocalFile,
  }) =>
      ReportAttachment(
        id: id ?? this.id,
        localPath: localPath ?? this.localPath,
        originalName: originalName ?? this.originalName,
        caption: caption ?? this.caption,
        managedLocalFile: managedLocalFile ?? this.managedLocalFile,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'originalName': originalName,
        'caption': caption,
        'managedLocalFile': managedLocalFile,
      };

  factory ReportAttachment.fromJson(Map<String, dynamic> json) =>
      ReportAttachment(
        id: json['id'] as String? ?? '',
        localPath: json['localPath'] as String? ?? '',
        originalName: json['originalName'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        managedLocalFile: json['managedLocalFile'] as bool? ?? false,
      );

  factory ReportAttachment.fromLegacyPath(String path, int index) {
    final normalized = path.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    final name =
        lastSlash >= 0 && lastSlash < normalized.length - 1
            ? normalized.substring(lastSlash + 1)
            : normalized;

    return ReportAttachment(
      id: 'legacy-$index',
      localPath: path,
      originalName: name,
      caption: '',
      managedLocalFile: false,
    );
  }
}
