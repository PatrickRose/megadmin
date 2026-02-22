# =============================================================================
# Build stage — compiles gems, installs node modules, precompiles assets
# =============================================================================
FROM ruby:3.3.4-bookworm AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libvips-dev \
      curl \
      git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 via nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

WORKDIR /app

# Install gems (cached unless Gemfile/Gemfile.lock change)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install

# Install JS dependencies (cached unless package.json/yarn.lock change)
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code and precompile assets
COPY . .
RUN SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile

# =============================================================================
# Development stage — full toolchain for local dev (used by docker-compose)
# =============================================================================
FROM build AS development

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

# Dev needs all gem groups
RUN bundle config unset --local without && \
    bundle install

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

# =============================================================================
# Production stage — runtime only, no build tools or Node.js
# =============================================================================
FROM ruby:3.3.4-slim-bookworm AS production

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
      curl \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

# Copy installed gems from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle

# Copy precompiled assets and application code from build stage
COPY --from=build /app /app

ENV RAILS_ENV=production

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
