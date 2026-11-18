# Nuxt SSR streaming: `useCookie` writes during render

With `experimental.ssrStreaming: true`, a `useCookie` write made while the page renders (here from a component six levels deep) is applied on the `app:rendered` hook. By then the streamed response has already sent its status and headers.

| App | Nuxt | Result |
|---|---|---|
| [`apps/nuxt-4`](apps/nuxt-4) | `4.6.4` | `setCookie` throws `ERR_HTTP_HEADERS_SENT`. The stream's error path then fails with `DevalueError` (`NUXT_E8009`). The HTML is cut off and `__NUXT_DATA__` is never sent, so the page cannot hydrate. |
| [`apps/nuxt-5`](apps/nuxt-5) | `nuxt-nightly@5x` | The page renders, but no `Set-Cookie` header is sent. The write is dropped with no warning in a production build. |

Routes in each app:

- `/none`: control, no cookie written
- `/early`: cookie written in the deep component's `setup`
- `/late`: cookie written after an `await` in the deep component

## Run

Requires pnpm (or bun) and Node 22.21+, 24.11+ or 26+.

```sh
pnpm install
pnpm build
pnpm check:4
pnpm check:5
```

Each check starts the production server, requests the three routes, and prints whether a `Set-Cookie` header arrived and whether the closing `__NUXT_DATA__` payload was sent.

Expected on `apps/nuxt-4`: `/none` has `payload-sent=1`; `/early` and `/late` have `payload-sent=0` and print the `NUXT_E8009` error.
Expected on `apps/nuxt-5`: all three have `payload-sent=1`, and `/early` and `/late` have `set-cookie=0`.
