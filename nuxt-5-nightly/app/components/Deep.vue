<script setup lang="ts">
const props = defineProps<{ level: number; mode: 'none' | 'early' | 'late' }>()
if (props.level === 5 && props.mode !== 'none') {
  if (props.mode === 'late') await new Promise(r => setTimeout(r, 300))
  useCookie('deep').value = `set-${props.mode}`
}
</script>

<template>
  <div>L{{ level }}<Deep v-if="level < 5" :level="level + 1" :mode="mode" /></div>
</template>
