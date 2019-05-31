package hello;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.annotation.QueryValue;

import java.util.concurrent.atomic.AtomicLong;

@Controller("/greeting") // <1>
public class GreetingController {
    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    @Get("/") // <2>
    @Produces(MediaType.APPLICATION_JSON) // <3>
    public Greeting index(@QueryValue String name) {
        return new Greeting(counter.incrementAndGet(),
                String.format(template, name));
    }
}
