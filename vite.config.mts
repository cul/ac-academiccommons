import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';

export default defineConfig({
  server: {
    port: 3036
  },
  plugins: [
    RubyPlugin(),
  ],
})
