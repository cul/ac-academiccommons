import { resolve } from 'path';
import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import inject from '@rollup/plugin-inject';

export default defineConfig({
  // resolve: {
  //   alias: {
  //     '@assets': resolve(__dirname, 'app/assets')
  //   }
  // },
  plugins: [
    inject({
      $: 'jquery',
      jQuery: 'jquery',
    }),
    RubyPlugin(),
  ],
})
