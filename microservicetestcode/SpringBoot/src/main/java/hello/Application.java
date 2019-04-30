package hello;

import org.springframework.boot.SpringApplication;
import java.lang.management.ManagementFactory;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
        long currentTime = System.currentTimeMillis();
        long vmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        System.out.println("STARTED Application started: "+ (currentTime - vmStartTime));
    }
}
