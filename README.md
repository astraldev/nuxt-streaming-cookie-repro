# Nuxt SSR streaming: `useCookie` writes during render

With `experimental.ssrStreaming: true`, `useCookie` writes its `Set-Cookie` header on the `app:rendered` hook. The streaming renderer sends the shell (the first chunk of HTML) before it calls that hook, so the status and headers are already committed. A cookie assigned in a plugin is affected too, because the plugin only sets the value.

| App | Nuxt | Result |
|---|---|---|
| [`apps/nuxt-4`](apps/nuxt-4) | `4.6.4` | `setCookie` throws `ERR_HTTP_HEADERS_SENT`. The stream's error path then fails with `DevalueError` (`NUXT_E8009`). The HTML is cut off and `__NUXT_DATA__` is never sent, so the page cannot hydrate. |
| [`apps/nuxt-5`](apps/nuxt-5) | `nuxt-nightly@5.0.0-2611172312-387a546` | The page renders, but the cookie is sent only if `app:rendered` runs before srvx calls `writeHead`. Otherwise it is dropped with no warning in a production build. |

Routes in each app:

- `/none`: no cookie written (control)
- `/plugin`: a plugin sets the cookie
- `/plugin-slow`: the same plugin, on a page with a 300 ms async component
- `/early`: a component six levels deep sets the cookie in `setup`
- `/late`: the same component sets the cookie after an `await`

## Run

Requires pnpm (or bun) and Node 22.21+, 24.11+ or 26+. Last run on Node 26.13.1.

```sh
pnpm install
pnpm build
pnpm check:4
pnpm check:5
```

Each check starts the production server of one app and requests the five routes. `set-cookie` is the number of `Set-Cookie` headers in the response. `payload-sent` is 1 when the closing `__NUXT_DATA__` script reached the client.

Expected output:

```text
apps/nuxt-4
/none         set-cookie=0 payload-sent=1
/plugin       set-cookie=0 payload-sent=0
/plugin-slow  set-cookie=0 payload-sent=0
/early        set-cookie=0 payload-sent=0
/late         set-cookie=0 payload-sent=0

apps/nuxt-5
/none         set-cookie=0 payload-sent=1
/plugin       set-cookie=1 payload-sent=1
/plugin-slow  set-cookie=0 payload-sent=1
/early        set-cookie=0 payload-sent=1
/late         set-cookie=0 payload-sent=1
```

`apps/nuxt-4` also prints a `NUXT_E8009` line for each route that is cut off.
