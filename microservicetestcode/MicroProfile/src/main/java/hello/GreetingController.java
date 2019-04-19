package hello;

import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.UriInfo;
import java.util.concurrent.atomic.AtomicLong;

/**
 *
 */
@Path("/greeting")
@ApplicationScoped
public class GreetingController {
    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Greeting sayHello(@Context UriInfo info) {
        return new Greeting(counter.incrementAndGet(),String.format(template, info.getQueryParameters().get("name").get(0)));
    }
}