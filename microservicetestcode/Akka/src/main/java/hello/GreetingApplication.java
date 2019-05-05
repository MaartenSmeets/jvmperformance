package hello;

import akka.actor.ActorSystem;
import akka.routing.RoundRobinPool;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.jaxrs.json.JacksonJsonProvider;
import org.glassfish.jersey.internal.inject.AbstractBinder;
import org.glassfish.jersey.server.ResourceConfig;
import scala.concurrent.duration.Duration;

import javax.annotation.PreDestroy;
import javax.ws.rs.ApplicationPath;
import java.util.concurrent.TimeUnit;

@ApplicationPath("/")
public class GreetingApplication extends ResourceConfig {

    private ActorSystem system;

    public GreetingApplication() {

        system = ActorSystem.create("ExampleSystem");
        system.actorOf(GreetingActor.mkProps().withRouter(new RoundRobinPool(5)), "greetingRouter");

        register(new AbstractBinder() {
            protected void configure() {
                bind(system).to(ActorSystem.class);
            }
        });

        register(new JacksonJsonProvider().
                configure(SerializationFeature.INDENT_OUTPUT, true));

        packages("hello");
    }

    @PreDestroy
    private void shutdown() {
        system.shutdown();
        system.awaitTermination(Duration.create(15, TimeUnit.SECONDS));
    }

}
