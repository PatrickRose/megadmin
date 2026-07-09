## 1. Adopt the modern stack (#279)

- [ ] 1.1 Add `propshaft`, `importmap-rails`, `turbo-rails`, `stimulus-rails`
- [ ] 1.2 Migrate JS entrypoints from Shakapacker to importmap; replace `@rails/ujs` with Turbo and port `data-confirm`/`data-method` behaviour
- [ ] 1.3 Keep Bootstrap CSS vendored so the app still renders

## 2. Rich text (#280)

- [ ] 2.1 Re-run `action_text:install` for importmap; pin `trix` + `@rails/actiontext`; verify editing and attachments

## 3. Tailwind build (#281)

- [ ] 3.1 Add `tailwindcss-rails`; create `app/assets/tailwind/application.css` with `@import "tailwindcss"`; wire `bin/dev` to run the watcher + server

## 4. Docker & deploy validation (#282)

- [ ] 4.1 Rework the Dockerfile asset build for Propshaft/tailwindcss-rails/importmap; slim build-time Node/Yarn but KEEP Node in the runtime image
- [ ] 4.2 Deploy to staging and confirm the image builds, `/up` is healthy, and PDF rendering (briefs & cast lists) still works

## 5. Remove Shakapacker (#283)

- [ ] 5.1 Remove the `shakapacker` gem; webpack/SWC/sass-loader npm deps; `config/shakapacker.yml`; `config/webpack`; `shakapacker_patch.rb`; the `webpack` docker-compose service; and the app `package.json`/`yarn.lock`
- [ ] 5.2 Confirm `bin/dev` and the production image both build with no Shakapacker/webpack references; suite green
