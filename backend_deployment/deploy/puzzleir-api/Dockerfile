FROM eclipse-temurin:21-jdk
RUN mkdir /opt/app
COPY PuzzleIR.jar /opt/app
WORKDIR /opt/app
# EXPOSE 8081/tcp
CMD ["java", "-jar", "/opt/app/PuzzleIR.jar"]
