<script setup lang="ts">
import DefaultTheme from 'vitepress/theme'
import { useData } from 'vitepress'
import HeroMap from './HeroMap.vue'

const { Layout } = DefaultTheme
const { frontmatter } = useData()
</script>

<template>
  <Layout>
    <template #home-hero-image v-if="frontmatter.layout === 'home'">
      <HeroMap />
    </template>
  </Layout>
</template>
