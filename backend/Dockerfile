# Bước 1: Sử dụng Ubuntu + JDK 25 và tự cài Maven để đảm bảo không lỗi format file
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

# Cài đặt Maven thủ công bằng công cụ quản lý gói của Linux
RUN apt-get update && apt-get install -y maven

# Copy toàn bộ mã nguồn vào và tiến hành build bằng lệnh mvn hệ thống
COPY . .
RUN mvn clean package -DskipTests

# Bước 2: Sử dụng JRE 25 mỏng nhẹ để chạy ứng dụng
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
