# Stage 1: Maven Build
FROM eclipse-temurin:17-jdk AS build

WORKDIR /app

# Maven wrapper es pom.xml eloszor (cache layer)
COPY mvnw mvnw.cmd pom.xml ./
COPY .mvn .mvn

# Dependency download (cache)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Forras kod masolasa
COPY src ./src

# Build (tesztek kihagyasa a gyorsabb deployment-ert)
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:17-jre

WORKDIR /app

# JAR masolasa a build stage-bol
COPY --from=build /app/target/*.jar app.jar

# Health check - Render kezeli a /actuator/health endpoint-ot

# Port expose (Render automatikusan allitja a PORT env var-t)
EXPOSE 8080

# Inditas - Render PORT env var hasznalata
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar app.jar"]
