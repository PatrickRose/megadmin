# =============================================================================
# Base stage — shared toolchain (Ruby, Node.js, Yarn), no app code
# =============================================================================
FROM ruby:4.0.5-bookworm AS base

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libvips-dev \
      curl \
      git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 via nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

WORKDIR /app

# =============================================================================
# Build stage — installs production gems, node modules, precompiles assets
# =============================================================================
FROM base AS build

# Install gems (cached unless Gemfile/Gemfile.lock change)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install

# Install JS dependencies (cached unless package.json/yarn.lock change).
# Download Puppeteer's version-matched Chrome for Testing under /app so it is
# copied into the production image (Debian's apt chromium drifts ahead of the
# Puppeteer version and fails to launch).
ENV PUPPETEER_CACHE_DIR=/app/.cache/puppeteer
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code and precompile assets
COPY . .
RUN SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production bundle exec rails assets:precompile

# =============================================================================
# Development stage — full toolchain for local dev (used by docker-compose)
# Branches from base so dev system packages are cached independently of
# Gemfile/yarn.lock changes.
# =============================================================================
FROM base AS development

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      pandoc \
      texlive-latex-base \
      texlive-fonts-recommended \
      texlive-latex-recommended \
      lmodern \
      chromium \
      chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Install gems (all groups including dev/test)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Install JS dependencies
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code
COPY . .

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

# =============================================================================
# Production stage — runtime only, no build tools.
# Uses the full (non-slim) bookworm image so Chromium has all the shared
# libraries it needs at render time. Node.js is required at runtime: Grover
# drives Puppeteer through a Node bridge to render PDFs (briefs and cast lists).
# =============================================================================
FROM ruby:4.0.5-bookworm AS production

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      libvips42 \
      pandoc \
      texlive-latex-base \
      texlive-fonts-recommended \
      texlive-latex-recommended \
      lmodern \
      chromium \
      chromium-driver \
      fonts-liberation \
      curl \
    && rm -rf /var/lib/apt/lists/*

# Node.js runtime — required by Grover (Puppeteer bridge) for PDF generation
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Use Puppeteer's own version-matched Chrome for Testing (copied from the build
# stage under /app/.cache/puppeteer) rather than the apt chromium binary, whose
# version drifts ahead of Puppeteer and fails to launch. The apt chromium
# package is still installed above to supply Chrome's shared libraries.
ENV PUPPETEER_CACHE_DIR=/app/.cache/puppeteer

WORKDIR /app

# Copy installed gems from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle

# Copy precompiled assets and application code from build stage
COPY --from=build /app /app

ENV RAILS_ENV=production

# Git SHA of the deployed build, passed in by CI. Sentry's ReleaseDetector
# reads SENTRY_RELEASE first, tying every event/trace to this release.
ARG SENTRY_RELEASE=""
ENV SENTRY_RELEASE=${SENTRY_RELEASE}

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
