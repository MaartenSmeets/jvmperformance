package hello;

import java.lang.management.ManagementFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import org.eclipse.microprofile.metrics.MetricUnits;
import org.eclipse.microprofile.metrics.annotation.Timed;
import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.UriInfo;

@ApplicationScoped
public class GreetingHandler {

    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();
    private static Boolean first = true;
    
    @Timed(name = "MessagesProcessed",
            description = "Monitor the time sayHello Method takes",
            unit = MetricUnits.MILLISECONDS,
            absolute = true)
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Greeting sayHello(@Context UriInfo info) {
        return new Greeting(counter.incrementAndGet(),String.format(template, info.getQueryParameters().get("name").get(0)));
    }
    
    public GreetingController() {
        super();
        if (first) {
            long currentTime = System.currentTimeMillis();
            long vmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
            System.out.println("STARTED Controller started: "+ (currentTime - vmStartTime));
            first=false;
        }
    }
}
