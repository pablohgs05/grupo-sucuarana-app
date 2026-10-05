import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'report_model.dart';
import 'report_pdf.dart';

typedef ReportPdfBytesBuilder = Future<Uint8List> Function(Report report);
typedef ReportPdfShareAction = Future<void> Function(
  Uint8List bytes, {
  required String filename,
});
typedef ReportPdfPrintAction = Future<bool> Function(
  Uint8List bytes, {
  required String filename,
});
typedef ReportPdfPreviewBuilder = Widget Function(
  BuildContext context,
  Uint8List bytes,
);

class ReportPdfPreviewPage extends StatefulWidget {
  const ReportPdfPreviewPage({
    super.key,
    required this.report,
    this.bytesBuilder,
    this.shareAction,
    this.printAction,
    this.previewBuilder,
  });

  final Report report;
  final ReportPdfBytesBuilder? bytesBuilder;
  final ReportPdfShareAction? shareAction;
  final ReportPdfPrintAction? printAction;
  final ReportPdfPreviewBuilder? previewBuilder;

  @override
  State<ReportPdfPreviewPage> createState() => _ReportPdfPreviewPageState();
}

class _ReportPdfPreviewPageState extends State<ReportPdfPreviewPage> {
  late Future<Uint8List> _pdfFuture;
  bool _actionInProgress = false;

  String get _filename => reportPdfFilename(widget.report);

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  void _loadPdf() {
    _pdfFuture = (widget.bytesBuilder ?? buildReportPdfBytes)(widget.report);
  }

  void _retry() {
    setState(_loadPdf);
  }

  Future<void> _share(Uint8List bytes) async {
    if (_actionInProgress) return;

    setState(() => _actionInProgress = true);
    try {
      await (widget.shareAction ?? shareReportPdfBytes)(
        bytes,
        filename: _filename,
      );
    } catch (_) {
      if (mounted) {
        _message('Não foi possível compartilhar o PDF.');
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
      }
    }
  }

  Future<void> _print(Uint8List bytes) async {
    if (_actionInProgress) return;

    setState(() => _actionInProgress = true);
    try {
      final printed = await (widget.printAction ?? printReportPdfBytes)(
        bytes,
        filename: _filename,
      );
      if (!printed && mounted) {
        _message('A impressão foi cancelada ou não pôde ser iniciada.');
      }
    } catch (_) {
      if (mounted) {
        _message('Não foi possível abrir a impressão.');
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Pré-visualização do PDF'),
        ),
        body: FutureBuilder<Uint8List>(
          future: _pdfFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('pdf-preview-loading'),
                ),
              );
            }

            final bytes = snapshot.data;
            if (snapshot.hasError || bytes == null || bytes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    key: const ValueKey('pdf-preview-error'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível gerar a pré-visualização do PDF.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: widget.previewBuilder?.call(context, bytes) ??
                      PdfPreview(
                        key: const ValueKey('pdf-preview'),
                        build: (_) async => bytes,
                        allowPrinting: false,
                        allowSharing: false,
                      ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('share-pdf'),
                            onPressed: _actionInProgress
                                ? null
                                : () => _share(bytes),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartilhar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('print-pdf'),
                            onPressed: _actionInProgress
                                ? null
                                : () => _print(bytes),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Imprimir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
