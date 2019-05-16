package hello;

import akka.NotUsed;
import akka.actor.ActorRef;
import akka.actor.ActorSystem;
import akka.dispatch.OnComplete;
import akka.http.javadsl.ConnectHttp;
import akka.http.javadsl.Http;
import akka.http.javadsl.marshallers.jackson.Jackson;
import akka.http.javadsl.model.HttpRequest;
import akka.http.javadsl.model.HttpResponse;
import akka.http.javadsl.server.AllDirectives;
import akka.http.javadsl.server.Route;
import akka.http.scaladsl.model.StatusCodes;
import akka.pattern.Patterns;
import akka.stream.ActorMaterializer;
import akka.stream.javadsl.Flow;
import akka.util.Timeout;
import scala.concurrent.Await;
import scala.concurrent.Future;
import scala.concurrent.duration.Duration;

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

        final Flow<HttpRequest, HttpResponse, NotUsed> routeFlow = app.createRoute(greetingActor, system).flow(system, materializer);
        http.bindAndHandle(routeFlow, ConnectHttp.toHost("localhost", 8080), materializer);

        System.out.println("Server online at http://localhost:8080/");
        //#http-server
    }

    //#main-class

    /**
     * Here you can define all the different routes you want to have served by this web server
     * Note that routes might be defined in separated classes
     */
    protected Route createRoute(ActorRef greetingActor, ActorSystem actorSystem) {
        Timeout timeout = new Timeout(Duration.create(2, "seconds"));
        return parameter("name", name -> concat(
                path("greeting", () ->
                        get(() -> {
                            Future<Object> future = Patterns.ask(greetingActor, name, timeout);
                            future.onComplete(new OnComplete<Object>() {
                                public void onComplete(Throwable failure, Object result) {
                                    if (failure != null) {
                                        if (failure.getMessage() != null) {
                                            result=new Greeting(java.lang.System.currentTimeMillis(),failure.getMessage());

                                        } else {
                                            result=new Greeting(java.lang.System.currentTimeMillis(),"Something went wrong");
                                        }
                                    }
                                }
                            }, actorSystem.dispatcher());
                            try {
                                Greeting res = ((Greeting)Await.result(future, timeout.duration()));
                                return complete(StatusCodes.OK(), res, Jackson.marshaller());
                            } catch (Exception E) {
                                return complete(StatusCodes.InternalServerError(),E,Jackson.marshaller());
                            }
                        }))));
    }
}
//#main-class


