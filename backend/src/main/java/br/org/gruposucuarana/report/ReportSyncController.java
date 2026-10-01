package br.org.gruposucuarana.report;

import java.time.Instant;
import java.util.Collection;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/reports")
@Validated
public class ReportSyncController {

    private final ConcurrentMap<String, StoredReport> reports = new ConcurrentHashMap<>();

    @PostMapping("/sync")
    public ResponseEntity<ReportSyncResponse> sync(@Valid @RequestBody ReportSyncRequest request) {
        final var existing = reports.putIfAbsent(request.id(), new StoredReport(request, Instant.now()));
        return ResponseEntity.ok(new ReportSyncResponse(
                request.id(),
                existing == null ? "accepted" : "already_synced",
                existing == null ? reports.get(request.id()).receivedAt() : existing.receivedAt()));
    }

    @GetMapping
    public Collection<ReportSyncResponse> list() {
        return reports.values().stream()
                .map(report -> new ReportSyncResponse(report.request().id(), "synced", report.receivedAt()))
                .toList();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReportSyncRequest> get(@PathVariable String id) {
        final var report = reports.get(id);
        return report == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(report.request());
    }

    private record StoredReport(ReportSyncRequest request, Instant receivedAt) {
    }
}
