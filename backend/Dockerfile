# Stage 1: Maven Build
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml ./
COPY src/main ./src/main
ENV MAVEN_OPTS="-Xmx512m -XX:MaxMetaspaceSize=256m"
RUN mvn package -Dmaven.test.skip=true -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]