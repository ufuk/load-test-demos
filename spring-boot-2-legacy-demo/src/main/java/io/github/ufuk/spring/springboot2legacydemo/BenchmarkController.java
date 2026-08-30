package io.github.ufuk.spring.springboot2legacydemo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@RestController
@RequestMapping("/benchmark")
public class BenchmarkController {

    @GetMapping("/io-bound")
    public IoBenchmarkResponse ioBound(
            @RequestParam(name = "value1", defaultValue = "0") int value1,
            @RequestParam(name = "value2", defaultValue = "0") int value2,
            @RequestParam(name = "delay", defaultValue = "100") long delay
    ) throws InterruptedException {
        if (delay > 0) {
            Thread.sleep(delay);
        }
        return new IoBenchmarkResponse(value1 + value2, delay);
    }

    @GetMapping("/cpu-bound")
    public CpuBenchmarkResponse cpuBound(
            @RequestParam(name = "iterations", defaultValue = "10000") int iterations
    ) throws NoSuchAlgorithmException {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] data = "benchmark-input-string".getBytes(StandardCharsets.UTF_8);

        for (int i = 0; i < iterations; i++) {
            data = digest.digest(data);
        }

        StringBuilder hexString = new StringBuilder();
        for (byte b : data) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }

        return new CpuBenchmarkResponse(hexString.toString(), iterations);
    }

}
