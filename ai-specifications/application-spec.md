# Inventory Management Application Specification

## 1. Application name and purpose

- Name: `inventory_management`
- Purpose: A Spring Boot back-end for managing a small grocery/general store inventory and checkout workflow.
- The project README defines a system that handles:
  - inventory for fruits & vegetables, processed foods, and stationery
  - stock updates and item lookup by name/barcode
  - purchase orders with payment type and optional membership
  - receipt generation and sales tracking
  - membership management
  - suggested items/recommendations based on previous purchases
  - CSV-based bootstrap/import workflow for inventory data

## 2. Programming language

- Java 11 (see pom.xml)
- The application uses Spring Boot, JPA, and REST controllers in Java.

## 3. Java version

- Java version: 11
- Evidence: `pom.xml` includes `<java.version>11</java.version>` and compiler source/target settings for Java 11.

## 4. Spring Boot version

- Spring Boot version: 2.2.6.RELEASE
- Evidence: parent POM uses `org.springframework.boot:spring-boot-starter-parent` with version `2.2.6.RELEASE`.

## 5. Maven/build configuration

- Project artifact: `com.kasperin:inventory_management`
- Version: `0.0.1-SNAPSHOT`
- Packaging: default Maven packaging is JAR (`jar`), because there is no `<packaging>war</packaging>` override.
- Build tool: Maven
- Main build plugins include:
  - `spring-boot-maven-plugin`
  - `maven-compiler-plugin` version 3.8.1
  - `maven-surefire-plugin` version 2.22.0
  - `maven-failsafe-plugin` version 2.22.0
  - `maven-site-plugin` version 3.7.1
- The build config also sets compiler args for MapStruct and java version 11.
- Notable config detail: the POM includes a stray `7` following the compiler arg block, which looks like a typo and may indicate legacy formatting issues.

## 6. Application port

- No explicit `server.port` is configured in the source tree.
- Default Spring Boot port is therefore 8080 unless overridden externally.
- Relevant config files exist for `application-dev.yml` and `application-prod.yml`, but neither sets a custom port.

## 7. Application startup command

Common startup commands:

- Development/local run: `mvn spring-boot:run`
- Packaged jar run: `mvn package` then `java -jar target/inventory_management-0.0.1-SNAPSHOT.jar`
- Profile-based startup: `mvn spring-boot:run -Dspring-boot.run.profiles=dev` or `prod`

The project contains `application-dev.yml` and `application-prod.yml`, so the intended deployment pattern is to run the app with Spring profiles selected by environment or command-line flags.

## 8. Maven test command

- Standard unit test command: `mvn test`
- Integration verification command: `mvn verify`
- The project uses Maven Surefire for unit tests and Maven Failsafe for integration tests.
- Local validation completed successfully in WSL Ubuntu with Java 11 and Maven 3.8.7.
- Latest validation result:
  - Tests run: 33
  - Failures: 0
  - Errors: 0
  - Skipped: 3
  - Build result: SUCCESS

## 9. Packaging type

- Packaging type: JAR (default Maven packaging)
- No WAR packaging configured.

## 10. Important dependencies

Core runtime dependencies from `pom.xml`:

- Spring Boot Web (`spring-boot-starter-web`)
- Spring Data JPA (`spring-boot-starter-data-jpa`)
- MySQL JDBC driver (`mysql-connector-java`)
- H2 database (`h2`)
- Spring Boot DevTools
- Jackson XML support (`jackson-dataformat-xml`)
- Spring HATEOAS (`spring-boot-starter-hateoas`)
- Bean Validation (`spring-boot-starter-validation`)
- Lombok
- MapStruct
- Swagger / Springfox (`springfox-swagger2`, `springfox-swagger-ui`)
- Apache Commons CSV
- Apache Commons Lang3
- JUnit 5 and Mockito for testing
- Univocity CSV parser
- Jersey server / Jakarta WS-RS API

## 11. Database used

- Primary runtime database: MySQL
- Evidence: `application-dev.yml` and `application-prod.yml` are configured with MySQL JDBC URLs:
  - `jdbc:mysql://localhost:3306/kasperin_dev`
  - `jdbc:mysql://localhost:3306/kasperin_prod`
- There is also an H2 database dependency and a default properties file that sets:
  - `spring.datasource.platform=h2`
- This indicates the project was designed for MySQL in dev/prod and includes H2 as a lighter fallback or convenience database.
- SQL setup script: `src/main/scripts/configure-mysql.sql` creates the `kasperin_dev` and `kasperin_prod` databases and service accounts.

## 12. REST API endpoints

The app exposes controller routes under `/api/v1`.

### Inventory item endpoints

- `GET /api/v1/items`
  - Lists all items in stock by default; `?all=all` returns all items.
- `GET /api/v1/fruitAndVeges`
  - lists all fruits/vegetables or filters by name
  - query params: `all`, `name`
- `GET /api/v1/fruitAndVeges/{id}`
- `GET /api/v1/fruitAndVeges/name/{name}`
- `POST /api/v1/fruitAndVeges`
- `PATCH /api/v1/fruitAndVeges/{id}`
- `DELETE /api/v1/fruitAndVeges/{ID}`

- `GET /api/v1/processedFoods`
  - supports query params `type`, `all`, `name`
- `GET /api/v1/processedFoods/name/{name}`
- `GET /api/v1/processedFoods/{id}`
- `POST /api/v1/processedFoods`
- `PATCH /api/v1/processedFoods/{id}`
- `DELETE /api/v1/processedFoods/{ID}`

- `GET /api/v1/stationary`
  - supports `all` and `name` query params
- `GET /api/v1/stationary/{id}`
- `GET /api/v1/stationary/name/{name}`
- `POST /api/v1/stationary`
- `PATCH /api/v1/stationary/{id}`
- `DELETE /api/v1/stationary/{id}`

### Membership endpoints

- `POST /api/v1/members`
- `GET /api/v1/members`
- `GET /api/v1/members/{id}`
- `PATCH /api/v1/members/{id}`
- `DELETE /api/v1/members/{ID}`

### Purchase order endpoints

- `GET /api/v1/purchase_orders`
- `GET /api/v1/purchase_orders/{id}`
- `POST /api/v1/purchase_orders`
- `PATCH /api/v1/purchase_orders/{id}`
- `DELETE /api/v1/purchase_orders/{id}`

### Recommendation endpoints

- `POST /api/v1/recommendations`
- `POST /api/v1/recommendations/associate`

### Ordered item analysis endpoint

- `GET /api/v1/orderedItems`
  - This controller accepts a request body for order analysis and returns an analysis DTO.

### Swagger UI

- Springfox is enabled, so the application exposes Swagger documentation at:
  - `http://localhost:8080/swagger-ui.html` (or `swagger-ui/index.html` depending on Springfox version)

## 13. Environment variables/configuration required

At minimum, the app expects database connection information for the active profile.

### Required Spring properties

- `spring.datasource.url`
- `spring.datasource.username`
- `spring.datasource.password`
- `spring.datasource.platform`
- `spring.jpa.hibernate.ddl-auto`
- `spring.jpa.database-platform`
- `spring.jpa.database`
- `spring.jpa.show-sql`

### Profile usage

- `application-dev.yml` and `application-prod.yml` are the main environment-specific profiles.
- Recommended activation pattern:
  - `SPRING_PROFILES_ACTIVE=dev`
  - `SPRING_PROFILES_ACTIVE=prod`

### Important caution

- Database credentials are embedded directly in source configuration files, which is a security risk for a production deployment.

## 14. External dependencies

External dependencies and runtime assumptions include:

- MySQL database service (for dev/prod)
- Spring Boot runtime environment with Java 11
- Maven build tool
- Swagger UI via Springfox
- H2 for optional local/test fallback
- Optional CSV input file ingestion through the project’s inventory bootstrap and CSV-related libraries

This is primarily a backend service and not a self-contained offline app; it depends on a relational database and a Java runtime.

## 15. Health-check endpoint, if available

- No actuator dependency is configured in `pom.xml`.
- No `management.endpoints` configuration or `/actuator` path is present in the source tree.
- There is no explicit health endpoint defined.
- Therefore, the app does not appear to expose a built-in health-check endpoint such as `/actuator/health`.
- Swagger UI is the most obvious operational endpoint available out-of-the-box.

## 16. Security concerns

These are the main security and operational concerns found during analysis:

- No Spring Security dependency or authentication layer is configured.
- No authorization rules are enforced; the APIs are publicly accessible.
- Database credentials are hard-coded into `application-dev.yml` and `application-prod.yml`.
- Example credentials and local host references are stored in source control.
- No TLS/HTTPS or reverse-proxy configuration is included.
- The project is exposing read/write inventory and purchase APIs without authentication.
- CSV and bootstrap data likely inserts sample inventory data on startup, which can be undesirable in production if the app is started in the wrong profile.
- Swagger UI exposes every controller endpoint to anyone who can reach the app.
- There is no secret management or environment variable abstraction beyond raw config files.

## 17. Runtime requirements

- Java 11 runtime required
- Maven 3.x recommended
- A MySQL server instance for dev/prod profiles
- Sufficient disk space for compiled jar and local database logs
- Typical Spring Boot server resource requirements: modest CPU/RAM for a small inventory service, but this is not a large-scale distributed system
- The application is intended to run as a single Spring Boot service instance.

## 18. Technical debt or compatibility issues

Potential issues and compatibility risks observed in the codebase:

- Spring Boot 2.2.6 is somewhat dated and may have compatibility issues with newer tooling or JDK versions.
- Java 11 is current for the project, but the app is not using a more recent Spring Boot baseline.
- The `pom.xml` mixes dependency versions that are not always aligned with the Spring Boot parent version. Examples include:
  - `spring-boot-starter-hateoas` pinned to `2.3.0.RELEASE` while the parent is `2.2.6.RELEASE`
  - `spring-integration-event` version `5.3.1.RELEASE` is not naturally aligned with the parent version at a glance
- The project includes `jakarta.ws.rs-api` and Jersey server dependencies, which may reflect legacy or mixed Java EE/Jakarta usage patterns.
- There are commented-out and stale profile notes, plus experimental code and commented sections in the bootstrap code.
- The `Bootstrap` component seeds data automatically on application startup, which is operationally risky in production and may create duplicate or inconsistent data if the app is restarted repeatedly.
- There is no explicit health endpoint or observability integration.
- The application source appears to have been built around an academic project or early prototype and contains a few legacy patterns (hard-coded local DB credentials, direct source-level secrets, minimal security, and older Swagger config).
local baseline fixes were required for older Spring HATEOAS compatibility, schema.sql, bootstrap enablement, and an outdated test expectation. That is useful evidence that the AI-generated and inherited code was reviewed rather than blindly accepted.

## Summary of repository findings

This repository is a Java/Spring Boot inventory management application focused on backend APIs for a grocery store. It manages stock for fruits, vegetables, processed foods, and stationery; supports purchase orders and memberships; and includes recommendation logic and Swagger-based API documentation.

The project expects Java 11 and Spring Boot 2.2.6, uses Maven with a JAR packaging model, and targets MySQL in dev/prod profiles while including H2 support. It exposes REST endpoints under `/api/v1`, but it does not define an actuator health endpoint or security configuration, and it stores database credentials in source files, which creates clear security and deployment concerns.

## Source evidence reviewed

- `README.md`
- `pom.xml`
- `src/main/java/com/kasperin/inventory_management/InventoryManagementApplication.java`
- `src/main/resources/application.properties`
- `src/main/resources/application-dev.yml`
- `src/main/resources/application-prod.yml`
- `src/main/resources/application-default.properties`
- `src/main/java/com/kasperin/inventory_management/controllers/**/*.java`
- `src/main/java/com/kasperin/inventory_management/bootstrap/Bootstrap.java`
- `src/main/java/com/kasperin/inventory_management/config/SwaggerConfig.java`
- `src/main/scripts/configure-mysql.sql`
- `src/test/java/**/*.java`

## Important note for infrastructure work

Per the request, this analysis intentionally does not create Docker, Kubernetes, Terraform, or GitHub Actions files and does not modify the existing application source code.
