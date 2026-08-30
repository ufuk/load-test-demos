package io.github.ufuk.spring.springboot2legacydemo;

public class CpuBenchmarkResponse {

    private final String hash;
    private final int iterations;

    public CpuBenchmarkResponse(String hash, int iterations) {
        this.hash = hash;
        this.iterations = iterations;
    }

    public String getHash() {
        return hash;
    }

    public int getIterations() {
        return iterations;
    }

}
