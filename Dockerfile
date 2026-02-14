FROM ruby:3.3.4-bookworm

# System dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libvips-dev \
      pandoc \
      texlive-latex-base \
      texlive-fonts-recommended \
      texlive-latex-recommended \
      chromium \
      chromium-driver \
      lmodern \
      curl \
      git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 via nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

# Set Puppeteer to use system Chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

# Install gems
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

COPY Gemfile Gemfile.lock ./
RUN if [ "$RAILS_ENV" = "production" ]; then \
      bundle config set --local without 'development test'; \
    fi && \
    bundle install

# Install JS dependencies
COPY package.json yarn.lock ./
RUN yarn install

# Copy the rest of the application
COPY . .

# Precompile assets for production
RUN if [ "$RAILS_ENV" = "production" ]; then \
      SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile; \
    fi

ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
