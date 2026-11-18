export default defineNuxtPlugin(() => {
  if (useRequestURL().pathname.startsWith('/plugin')) {
    useCookie('from-plugin').value = 'set-in-plugin'
  }
})
