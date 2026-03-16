# Stage 1: Maven Build
FROM eclipse-temurin:21-jdk AS build

WORKDIR /app

COPY mvnw mvnw.cmd pom.xml ./
COPY .mvn .mvn
COPY src ./src

RUN chmod +x mvnw && ./mvnw package -Dmaven.test.skip=true -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]
