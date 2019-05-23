package hello;

import java.io.IOException;
import java.io.OutputStream;
import java.lang.management.ManagementFactory;
import java.net.InetSocketAddress;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicLong;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

public class Application {
    private static final String template = "Hello, %s!";
    private final static AtomicLong counter = new AtomicLong();

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/greeting", new MyHandler());
        //Thread control is given to executor service.
        server.setExecutor(java.util.concurrent.Executors.newCachedThreadPool());
        server.start();

        long currentTime = System.currentTimeMillis();
        long vmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        System.out.println("STARTED Application started: "+ (currentTime - vmStartTime));
    }

    static public Map<String, String> queryToMap(String query) {
        Map<String, String> result = new HashMap<>();
        for (String param : query.split("&")) {
            String[] entry = param.split("=");
            if (entry.length > 1) {
                result.put(entry[0], entry[1]);
            }else{
                result.put(entry[0], "");
            }
        }
        return result;
    }

    static class MyHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange t) throws IOException {
            String template = "{\"id\":%d,\"content\":\"Hello, %s!\"}";
            String response = String.format(template,counter.incrementAndGet(),queryToMap(t.getRequestURI().getQuery()).get("name"));
            //long threadId = Thread.currentThread().getId();
            //System.out.println("I am thread " + threadId );
            //response = response + "Thread Id = "+threadId;
            t.getResponseHeaders().add("Content-Type","application/json;charset=UTF-8");
            t.sendResponseHeaders(200, response.getBytes().length);
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
