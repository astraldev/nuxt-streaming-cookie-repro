# Nuxt SSR streaming + late `useCookie` writes

With `experimental.ssrStreaming: true`, a `useCookie` write during render
(here from a component 6 levels deep) is applied on the `app:rendered` hook,
after the streamed response has already committed its headers.

| App | Nuxt | Result |
|---|---|---|
| `nuxt-4.6` | 4.6.4 | `ERR_HTTP_HEADERS_SENT` is thrown, then `NUXT_E8009` (`DevalueError: Cannot stringify arbitrary non-POJOs`). The HTML is truncated and `__NUXT_DATA__` is never sent. |
| `nuxt-5-nightly` | `nuxt-nightly@5x` | Page renders, but no `Set-Cookie` header is sent. The cookie is silently dropped. |

Pages: `/none` (control, no cookie), `/early` (written in the deep component's setup), `/late` (written after an `await`).

## Run

```sh
cd nuxt-4.6 && pnpm install --ignore-workspace && pnpm build && cd ..
./check.sh nuxt-4.6 4101

cd nuxt-5-nightly && pnpm install --ignore-workspace && pnpm build && cd ..
./check.sh nuxt-5-nightly 4102
```

Expected output, Nuxt 4.6.4: `/none` has `payload-sent=1`, `/early` and `/late` have `payload-sent=0`, plus the error lines.
Nuxt 5 nightly: all three have `payload-sent=1`, `set-cookie=0` on `/early` and `/late`.

Tested on Node 22.15.1.
