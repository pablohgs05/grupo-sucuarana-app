package br.org.gruposucuarana.report;

import java.time.Instant;

public record ReportSyncResponse(
        String id,
        String status,
        Instant receivedAt) {
}
