# nuxt5-pr

The routes of this repro, packaged to run in the `playground/` of a `nuxt/nuxt` checkout in development. Use it to check a fix branch against the same pages as the issue.

The apps in `apps/` run production builds of published Nuxt versions. This folder runs a local checkout in dev, so it can show the development-only `NUXT_E7012` warning.

## Run

```sh
./nuxt5-pr/run.sh ~/path/to/nuxt 3102
```

The script copies `app/` and `nuxt.config.ts` into the checkout's `playground/`, starts `pnpm play`, requests `/none`, `/plugin`, `/early` and `/late`, prints the result of each, and prints the `NUXT_E7012`, `NUXT_E8002` and `NUXT_E8009` lines from the dev server log. It then stops the server and restores `playground/`. It refuses to run if `playground/app/pages`, `components` or `plugins` already exist.

`set-cookie` is the number of `Set-Cookie` headers in the response. `payload-sent` is 1 when the closing `__NUXT_DATA__` script reached the client.

## Result in dev

Observed on Node 26.13.1, `experimental.ssrStreaming: true`.

| Route | `upstream/main` at `97821705d` | PR branch |
|---|---|---|
| `/none` | no cookie | no cookie |
| `/plugin` | cookie sent | cookie sent |
| `/early` | cookie dropped | cookie sent |
| `/late` | cookie dropped | cookie dropped, `NUXT_E7012` printed |

On both, `/none` also prints `NUXT_E8002`, so that warning does not depend on a cookie being written.

On the PR branch, `/late` prints:

```text
WARN  [NUXT_E7012] Cookie deep was changed after SSR streaming had already sent the response headers, so it was not sent to the client.
╰▶ fix: Set the cookie in a plugin, which runs before the headers are sent, or opt the route out of streaming with routeRules: { '/path': { streaming: false } }.
```
