package hello

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.springframework.context.ConfigurableApplicationContext
import org.springframework.test.web.reactive.server.WebTestClient
import org.springframework.test.web.reactive.server.expectBody

class IntegrationTests {

	private val client = WebTestClient.bindToServer().baseUrl("http://localhost:8080").build()

	private lateinit var context: ConfigurableApplicationContext

	@BeforeAll
	fun beforeAll() {
		context = app.run(profiles = "test")
	}

	@Test
	fun `Request root endpoint`() {
		client.get().uri("/greeting?name=Maarten").exchange()
				.expectStatus().is2xxSuccessful
				.expectBody<String>().isEqualTo("{\"id\":1,\"content\":\"Maarten\"}")
	}

	@AfterAll
	fun afterAll() {
		context.close()
	}
}