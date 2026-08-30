package io.github.ufuk.spring.springboot2legacydemo;

public class IoBenchmarkResponse {

    private final int result;
    private final long delayMs;

    public IoBenchmarkResponse(int result, long delayMs) {
        this.result = result;
        this.delayMs = delayMs;
    }

    public int getResult() {
        return result;
    }

    public long getDelayMs() {
        return delayMs;
    }

}
