package io.github.ufuk.spring.springboot4demo;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasLength;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BenchmarkController.class)
class BenchmarkControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldReturnSumForIoBoundEndpoint() throws Exception {
        mockMvc.perform(get("/benchmark/io-bound")
                        .param("value1", "3")
                        .param("value2", "5")
                        .param("delay", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result", is(8)))
                .andExpect(jsonPath("$.delayMs", is(0)));
    }

    @Test
    void shouldReturnValidHashForCpuBoundEndpoint() throws Exception {
        mockMvc.perform(get("/benchmark/cpu-bound")
                        .param("iterations", "100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hash", hasLength(64)))
                .andExpect(jsonPath("$.iterations", is(100)));
    }

}
