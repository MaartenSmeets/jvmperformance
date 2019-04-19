package hello;

import org.springframework.fu.jafu.ConfigurationDsl;
import org.springframework.fu.jafu.JafuApplication;

import java.util.function.Consumer;

import static org.springframework.fu.jafu.Jafu.webApplication;
import static org.springframework.fu.jafu.web.WebFluxServerDsl.server;

public class Application {

    public static void main(String[] args) {

        Consumer<ConfigurationDsl> webFluxConfig = c -> c
                .beans(beans -> beans.bean(GreetingHandler.class))
                .enable(
                        server(
                                server -> server
                                        .router(router -> {
                                            GreetingHandler greetingHandler = c.ref(GreetingHandler.class);
                                            router.GET("/greeting", greetingHandler::hello);
                                        }).codecs(codecs -> codecs.string().jackson())
                        )
                );

        JafuApplication jafu = webApplication(app -> app.enable(webFluxConfig));

        jafu.run(args);
    }
}