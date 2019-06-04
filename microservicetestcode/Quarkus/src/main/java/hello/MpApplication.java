package hello;

import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;
import java.lang.management.ManagementFactory;

/**
 * based on https://github.com/OpenLiberty/sample-getting-started
 */
@ApplicationPath("/")
@ApplicationScoped
public class MpApplication extends Application {
     public MpApplication() {
        super();
        long currentTime = System.currentTimeMillis();
        long vmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        System.out.println("STARTED Application started: "+ (currentTime - vmStartTime));
    }
}
