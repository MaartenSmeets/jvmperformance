package hello;

import akka.actor.AbstractActor;
import akka.actor.Props;
import akka.actor.UntypedActor;
import akka.event.Logging;
import akka.event.LoggingAdapter;

import java.util.concurrent.atomic.AtomicLong;

public class GreetingActor extends UntypedActor {

    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    public static Props mkProps() {
        return Props.create(GreetingActor.class);
    }

    @Override
    public void onReceive(Object message) throws Exception {

        if (message instanceof String) {
            //log.debug("received message: " + (Integer) message);
            Greeting greeting = new Greeting(counter.incrementAndGet(), String.format(template, (String)message));
            getSender().tell(greeting, getSelf());
        } else {
            unhandled(message);
        }

    }
}