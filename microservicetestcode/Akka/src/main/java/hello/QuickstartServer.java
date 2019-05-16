package hello;

import akka.NotUsed;
import akka.actor.ActorRef;
import akka.actor.ActorSystem;
import akka.http.javadsl.ConnectHttp;
import akka.http.javadsl.Http;
import akka.http.javadsl.marshallers.jackson.Jackson;
import akka.http.javadsl.model.HttpRequest;
import akka.http.javadsl.model.HttpResponse;
import akka.http.javadsl.model.StatusCodes;
import akka.http.javadsl.server.AllDirectives;
import akka.http.javadsl.server.Route;
import akka.pattern.Patterns;
import static akka.pattern.PatternsCS.ask;
import akka.stream.ActorMaterializer;
import akka.stream.javadsl.Flow;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

//#main-class
public class QuickstartServer extends AllDirectives {

    //#main-class

    public static void main(String[] args) throws Exception {
        //#server-bootstrapping
        // boot up server using the route as defined below
        ActorSystem system = ActorSystem.create("helloAkkaHttpServer");

        final Http http = Http.get(system);
        final ActorMaterializer materializer = ActorMaterializer.create(system);
        //#server-bootstrapping

        ActorRef greetingActor = system.actorOf(GreetingActor.mkProps(), "greetingActor");

        //#http-server
        //In order to access all directives we need an instance where the routes are define.
        QuickstartServer app = new QuickstartServer();

        final Flow<HttpRequest, HttpResponse, NotUsed> routeFlow = app.createRoute(greetingActor).flow(system, materializer);
        http.bindAndHandle(routeFlow, ConnectHttp.toHost("localhost", 8080), materializer);

        System.out.println("Server online at http://localhost:8080/");
        //#http-server
    }

    //#main-class

    /**
     * Here you can define all the different routes you want to have served by this web server
     * Note that routes might be defined in separated classes like the current case
     */
    protected Route createRoute(ActorRef greetingActor) {
        return parameter("name", name -> concat(
                path("greeting", () ->
                        get(() ->
                                complete(StatusCodes.OK)))));
    }

}
//#main-class


