package hello;

import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

import java.util.concurrent.atomic.AtomicLong;

public class GreetingHandler {

    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    public Mono<ServerResponse> hello(ServerRequest request) {
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(BodyInserters.fromObject(new Greeting(counter.incrementAndGet(), String.format(template, request.queryParam("name").get()))));
    }

}