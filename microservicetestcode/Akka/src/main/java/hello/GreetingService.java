package hello;

import akka.actor.ActorSelection;
import akka.actor.ActorSystem;
import akka.dispatch.OnComplete;
import akka.event.LoggingAdapter;
import akka.pattern.Patterns;
import akka.util.Timeout;
import org.glassfish.jersey.server.ManagedAsync;
import scala.concurrent.Future;
import scala.concurrent.duration.Duration;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.QueryParam;
import javax.ws.rs.Produces;
import javax.ws.rs.container.AsyncResponse;
import javax.ws.rs.container.Suspended;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.HashMap;

//based on https://github.com/pofallon/jersey2-akka-java

@Path("/greeting")
public class GreetingService {

    @Context ActorSystem actorSystem;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @ManagedAsync
    public void getExamples (
            @QueryParam("name") String name,
            @Suspended final AsyncResponse res) {

        ActorSelection greetingActor = actorSystem.actorSelection("/user/greetingRouter");

        Timeout timeout = new Timeout(Duration.create(2, "seconds"));

        Future<Object> future = Patterns.ask(greetingActor, name, timeout);

        future.onComplete(new OnComplete<Object>() {

            public void onComplete(Throwable failure, Object result) {

                if (failure != null) {
                    if (failure.getMessage() != null) {
                        HashMap<String,String> response = new HashMap<String,String>();
                        response.put("error", failure.getMessage());
                        res.resume(Response.serverError().entity(response).build());
                    } else {
                        res.resume(Response.serverError());
                    }
                } else {
                    res.resume(Response.ok().entity(result).build());
                }
            }
        }, actorSystem.dispatcher());

    }

}
