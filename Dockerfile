# ==========================================
# Stage 1: Build the Flutter Web application
# ==========================================
FROM debian:bookworm-slim AS build

# Install necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable branch
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configure Flutter and pre-cache web artifacts
RUN flutter config --no-analytics --enable-web
RUN flutter precache --web

# Copy project files and build release web
WORKDIR /app
COPY thesis /app/thesis
WORKDIR /app/thesis

RUN flutter pub get
RUN flutter build web --release

# ==========================================
# Stage 2: Production Nginx Server
# ==========================================
FROM nginx:alpine

# Copy compiled web files
COPY --from=build /app/thesis/build/web /usr/share/nginx/html

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

ENV PORT=80
EXPOSE 80

# Dynamically substitute Railway's $PORT at runtime
CMD ["/bin/sh", "-c", "sed -i 's/PORT_PLACEHOLDER/'\"${PORT:-80}\"'/g' /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]
