package io.github.ufuk.spring.springboot2demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

@RestController
@RequestMapping("benchmark")
public class BenchmarkController {

    @GetMapping("io-bound")
    public IoBenchmarkResponse ioBound(
            @RequestParam(required = false, defaultValue = "0") Long value1,
            @RequestParam(required = false, defaultValue = "0") Long value2,
            @RequestParam(required = false, defaultValue = "100") Long delay) throws InterruptedException {
        if (delay > 0) {
            Thread.sleep(delay);
        }
        return new IoBenchmarkResponse(value1 + value2, delay);
    }

    @GetMapping("cpu-bound")
    public CpuBenchmarkResponse cpuBound(
            @RequestParam(required = false, defaultValue = "10000") Integer iterations) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] data = "load-test-benchmark-seed-data".getBytes(StandardCharsets.UTF_8);
        for (int i = 0; i < iterations; i++) {
            data = md.digest(data);
        }
        return new CpuBenchmarkResponse(HexFormat.of().formatHex(data), iterations);
    }

}
