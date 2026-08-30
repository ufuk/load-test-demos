package io.github.ufuk.spring.springboot2legacydemo;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RunWith(SpringRunner.class)
@WebMvcTest(BenchmarkController.class)
public class BenchmarkControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void shouldReturnSumForIoBoundEndpoint() throws Exception {
        mockMvc.perform(get("/benchmark/io-bound")
                        .param("value1", "3")
                        .param("value2", "5")
                        .param("delay", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result", is(8)))
                .andExpect(jsonPath("$.delayMs", is(0)));
    }

    @Test
    public void shouldReturnValidHashForCpuBoundEndpoint() throws Exception {
        mockMvc.perform(get("/benchmark/cpu-bound")
                        .param("iterations", "100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hash", notNullValue()))
                .andExpect(jsonPath("$.iterations", is(100)));
    }

}
