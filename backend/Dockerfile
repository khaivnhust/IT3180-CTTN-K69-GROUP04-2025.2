# Bước 1: Sử dụng Maven kết hợp với JDK 25 để build dự án
FROM maven:3.9.6-eclipse-temurin-25 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Bước 2: Sử dụng JDK 25 mỏng nhẹ để chạy ứng dụng
FROM eclipse-temurin:25-jdk-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
