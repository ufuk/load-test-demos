package io.github.ufuk.spring.springboot2demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("demo")
public class DemoController {

    @GetMapping("sum")
    public DemoSumResponse sum(@RequestParam Long value1, @RequestParam Long value2) throws InterruptedException {
        Thread.sleep(100);
        return new DemoSumResponse(value1 + value2);
    }

}
