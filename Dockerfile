FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

COPY pom.xml .
COPY src ./src

RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:17-jre-jammy

RUN groupadd --system spring && useradd --system --gid spring --create-home spring

WORKDIR /app

COPY --from=build /build/target/inventory_management-0.0.1-SNAPSHOT.jar /app/app.jar

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]