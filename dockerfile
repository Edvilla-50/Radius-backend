# Build stage
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# 1. Copy dependencies first (keeps this step fast)
COPY pom.xml .

# 2. CACHE BUSTER: Change this version number whenever your code won't refresh!
ARG CACHE_BUST=1
RUN echo "Force recompile version: ${CACHE_BUST}"

# 3. Copy source and force a total re-update package
COPY src ./src
RUN mvn clean package -U -DskipTests

# Run stage
FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

ENV PORT=8080
EXPOSE 8080

CMD ["java", "-jar", "app.jar"]