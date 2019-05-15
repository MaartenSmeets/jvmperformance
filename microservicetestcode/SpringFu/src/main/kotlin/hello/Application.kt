package hello

import org.springframework.fu.kofu.web.server
import org.springframework.fu.kofu.webApplication
import org.springframework.http.MediaType
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse.ok
import java.util.concurrent.atomic.AtomicLong


val app = webApplication {
    beans {
        bean<GreetingHandler>()
    }
    server {
        port = 8080
        router {
            val handler = ref<GreetingHandler>()
            GET("/greeting", handler::json)
            contentType(MediaType.APPLICATION_JSON)
        }
        codecs {
            string()
            jackson()
        }
    }
}

data class Greeting(val id: Long, val content: String)

class GreetingHandler {
    private val template = "Hello, %s!"
    private val counter = AtomicLong()
    fun json(request: ServerRequest) = ok().syncBody(Greeting(counter.incrementAndGet(), String.format(request.queryParam("name").get(), template)))
}

fun main() {
    app.run()
}
