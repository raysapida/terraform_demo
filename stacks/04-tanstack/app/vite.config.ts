import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'
import { nitro } from 'nitro/vite'

// The whole deploy target is one word: preset 'aws_lambda'. Nitro turns the
// app into .output/server/index.mjs exporting `handler` (the Lambda) and
// .output/public (the static assets, for S3 behind CloudFront). The Terraform
// in ../terraform is built around exactly those two directories.
export default defineConfig({
  resolve: { tsconfigPaths: true },
  plugins: [
    nitro({
      preset: 'aws_lambda',
      // One file instead of lazily loaded chunks: faster cold starts, and a
      // simpler zip. Recommended by Nitro's AWS Lambda docs.
      inlineDynamicImports: true,
    }),
    tanstackStart(),
    viteReact(),
  ],
})
