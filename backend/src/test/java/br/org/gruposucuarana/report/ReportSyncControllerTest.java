package br.org.gruposucuarana.report;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import br.org.gruposucuarana.config.SecurityConfig;

@WebMvcTest(ReportSyncController.class)
@Import(SecurityConfig.class)
class ReportSyncControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void syncIsIdempotent() throws Exception {
        final var body = """
                {
                  "id": "report-1",
                  "title": "Busca",
                  "location": "São José dos Campos",
                  "description": "Operação de campo",
                  "occurredAt": "2026-04-10T08:00:00Z",
                  "data": {"operationType": "busca"}
                }
                """;

        mockMvc.perform(post("/api/reports/sync").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("accepted"));

        mockMvc.perform(post("/api/reports/sync").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("already_synced"));
    }
}
