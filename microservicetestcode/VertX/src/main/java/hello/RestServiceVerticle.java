package hello;

import io.micrometer.prometheus.PrometheusMeterRegistry;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.core.Vertx;
import io.vertx.core.VertxOptions;
import io.vertx.core.json.Json;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import io.vertx.micrometer.Label;
import io.vertx.micrometer.MicrometerMetricsOptions;
import io.vertx.micrometer.PrometheusScrapingHandler;
import io.vertx.micrometer.VertxPrometheusOptions;
import io.vertx.micrometer.backends.BackendRegistries;

import java.lang.management.ManagementFactory;
import java.util.EnumSet;
import java.util.concurrent.atomic.AtomicLong;

public class RestServiceVerticle extends AbstractVerticle {

    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    public RestServiceVerticle() {
        super();
        long currentTime = System.currentTimeMillis();
        long vmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        System.out.println("STARTED Controller started: " + (currentTime - vmStartTime));
    }

    @Override
    public void start(Future<Void> future) {

        MicrometerMetricsOptions options = new MicrometerMetricsOptions()
                .setPrometheusOptions(new VertxPrometheusOptions().setEnabled(true))
                .setLabels(EnumSet.of(Label.HTTP_CODE, Label.HTTP_PATH))
                .setEnabled(true);

        vertx = Vertx.vertx(new VertxOptions().setMetricsOptions(options));

        Router router = Router.router(this.vertx);
        router.route("/metrics").handler(PrometheusScrapingHandler.create());
        router.get("/greeting").handler(this::getGreeting);

        this.vertx.createHttpServer()
                .requestHandler(router::accept)
                .listen(config().getInteger("http.port", 8080), result -> {
                    if (result.succeeded()) {
                        future.complete();
                    } else {
                        future.fail(result.cause());
                    }
                });

    }

    private void getGreeting(RoutingContext routingContext) {
        String name = routingContext.request()
                .getParam("name");
        Greeting greeting = new Greeting(counter.incrementAndGet(), String.format(template, name));

        routingContext.response()
                .putHeader("content-type", "application/json")
                .setStatusCode(200)
                .end(Json.encode(greeting));
    }

}
