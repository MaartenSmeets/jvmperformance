package hello;

import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

/**
 * based on https://github.com/OpenLiberty/sample-getting-started
 */
@ApplicationPath("/")
@ApplicationScoped
public class MpApplication extends Application {
}