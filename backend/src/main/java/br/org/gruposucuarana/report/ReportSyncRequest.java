package br.org.gruposucuarana.report;

import java.time.Instant;
import java.util.Map;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ReportSyncRequest(
        @NotBlank String id,
        @NotBlank String title,
        @NotBlank String location,
        @NotBlank String description,
        @NotNull Instant occurredAt,
        @NotNull Map<String, Object> data) {
}
