# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

# Maven is only needed at build time — not shipped in the final image
RUN apk add --no-cache maven

WORKDIR /app

# Dependency layer (cached as long as pom.xml doesn't change)
COPY pom.xml ./
RUN mvn dependency:go-offline -q

# Build the fat JAR
COPY src src
RUN mvn package -DskipTests -q

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

# Run as non-root for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

ENV SERVER_PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- "http://localhost:${SERVER_PORT}/actuator/health" || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
