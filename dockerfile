# Use Java 17 (match your project version if different)
FROM eclipse-temurin:17-jdk-alpine

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build the app using Maven wrapper
RUN ./mvnw clean package -DskipTests

# Run the generated JAR
CMD ["java", "-jar", "target/*.jar"]