package io.github.ufuk.spring.springboot2demo;

public class DemoSumResponse {

    private Long result;

    public DemoSumResponse(Long result) {
        this.result = result;
    }

    public Long getResult() {
        return result;
    }

    public void setResult(Long result) {
        this.result = result;
    }

}