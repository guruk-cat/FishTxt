import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

export default defineConfig({
  plugins: [viteSingleFile()],
  build: {
    outDir: '../FishTxt/Resources',
    emptyOutDir: false,
    rollupOptions: {
      output: {
        entryFileNames: 'editor.html',
      },
    },
  },
})
