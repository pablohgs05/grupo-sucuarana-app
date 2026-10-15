package br.org.gruposucuarana.report;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.util.UUID;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import br.org.gruposucuarana.config.SecurityConfig;

@WebMvcTest(ReportSyncController.class)
@Import(SecurityConfig.class)
class ReportSyncControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper mapper;

    private ObjectNode report() {
        var body = mapper.createObjectNode();
        body.put("id", UUID.randomUUID().toString());
        body.put("title", "Relatório fictício");
        body.put("location", "Local fictício");
        body.put("description", "Operação fictícia");
        body.put("occurredAt", "2026-04-10T08:00:00Z");
        body.putObject("data").put("operationType", "busca");
        return body;
    }

    @Test
    void syncIsIdempotentAndPreservesOriginalContentAndTimestamp() throws Exception {
        var body = report();
        var first = mockMvc.perform(post("/api/reports/sync")
                .contentType(MediaType.APPLICATION_JSON).content(body.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(body.get("id").asText()))
                .andExpect(jsonPath("$.status").value("accepted"))
                .andExpect(jsonPath("$.receivedAt").isNotEmpty())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        body.put("title", "Tentativa de sobrescrita");
        mockMvc.perform(post("/api/reports/sync")
                .contentType(MediaType.APPLICATION_JSON).content(body.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("already_synced"))
                .andExpect(jsonPath("$.receivedAt").value(mapper.readTree(first).get("receivedAt").asText()));
        mockMvc.perform(get("/api/reports/{id}", body.get("id").asText()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Relatório fictício"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"id", "title", "location", "description", "occurredAt", "data"})
    void rejectsMissingRequiredFieldsWithoutStoringReport(String field) throws Exception {
        var body = report();
        var id = body.get("id").asText();
        body.remove(field);
        rejectAndVerifyAbsent(body.toString(), id);
    }

    @ParameterizedTest
    @ValueSource(strings = {"id", "title", "location", "description", "occurredAt", "data"})
    void rejectsNullRequiredFields(String field) throws Exception {
        var body = report();
        var id = body.get("id").asText();
        body.putNull(field);
        rejectAndVerifyAbsent(body.toString(), id);
    }

    @ParameterizedTest
    @ValueSource(strings = {"id", "title", "location", "description"})
    void rejectsBlankRequiredText(String field) throws Exception {
        var body = report();
        var id = body.get("id").asText();
        body.put(field, " \t\n");
        rejectAndVerifyAbsent(body.toString(), id);
    }

    @Test
    void rejectsInvalidDateAndMalformedJson() throws Exception {
        var body = report();
        body.put("occurredAt", "not-a-date");
        rejectAndVerifyAbsent(body.toString(), body.get("id").asText());
        mockMvc.perform(post("/api/reports/sync").contentType(MediaType.APPLICATION_JSON).content("{"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/reports/sync").contentType(MediaType.TEXT_PLAIN).content("report"))
                .andExpect(status().isUnsupportedMediaType());
    }

    @Test
    void reportsRemainIsolatedAndListContainsBothIds() throws Exception {
        var first = report();
        first.withObject("data").put("notes", "Somente primeiro");
        var second = report();
        second.withObject("data").put("notes", "Somente segundo");
        for (var body : new ObjectNode[] {first, second}) {
            mockMvc.perform(post("/api/reports/sync").contentType(MediaType.APPLICATION_JSON).content(body.toString()))
                    .andExpect(status().isOk());
            var result = mockMvc.perform(get("/api/reports/{id}", body.get("id").asText()))
                    .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
            assertThat(mapper.readTree(result)).isEqualTo(body);
        }
        mockMvc.perform(get("/api/reports"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", org.hamcrest.Matchers.hasItems(
                        first.get("id").asText(), second.get("id").asText())));
        mockMvc.perform(get("/api/reports/{id}", UUID.randomUUID().toString()))
                .andExpect(status().isNotFound());
    }

    @Test
    void corsAllowsLocalAppButRejectsUntrustedOrigin() throws Exception {
        mockMvc.perform(options("/api/reports/sync")
                .header("Origin", "http://localhost:54321")
                .header("Access-Control-Request-Method", "POST")
                .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:54321"));
        mockMvc.perform(options("/api/reports/sync")
                .header("Origin", "https://untrusted.example")
                .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isForbidden());
    }

    private void rejectAndVerifyAbsent(String body, String id) throws Exception {
        mockMvc.perform(post("/api/reports/sync").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/reports/{id}", id)).andExpect(status().isNotFound());
    }
}
