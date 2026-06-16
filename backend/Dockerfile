# Bước 1: Sử dụng chính JDK 25 để build dự án thông qua Maven Wrapper (mvnw)
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY . .
# Cấp quyền thực thi cho file chạy maven wrapper và tiến hành build
RUN chmod +x ./mvnw && ./mvnw clean package -DskipTests

# Bước 2: Sử dụng JDK 25 mỏng nhẹ để chạy ứng dụng
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
