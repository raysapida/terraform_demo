import { createFileRoute } from '@tanstack/react-router'
import { createServerFn } from '@tanstack/react-start'

// Module scope survives between invocations while Lambda keeps the container
// warm. Reload the page and watch the count climb; wait long enough (or
// redeploy) and it starts again from 1 — a cold start, visible.
let invocations = 0
const containerStartedAt = new Date().toISOString()

// Runs only on the server. During the first page load the loader calls it
// in-process inside the Lambda — no HTTP round trip — so nothing here depends
// on CloudFront forwarding POSTs.
const getRenderInfo = createServerFn({ method: 'GET' }).handler(async () => {
  invocations += 1
  return {
    renderedBy: process.env.AWS_LAMBDA_FUNCTION_NAME ?? 'vite dev server',
    region: process.env.AWS_REGION ?? 'local',
    node: process.version,
    memoryMb: process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE ?? '—',
    renderedAt: new Date().toISOString(),
    containerStartedAt,
    invocations,
  }
})

export const Route = createFileRoute('/')({
  loader: () => getRenderInfo(),
  component: Home,
})

function Home() {
  const info = Route.useLoaderData()

  return (
    <main>
      <h1>Rendered in a Lambda</h1>
      <p className="lede">
        HTML from a function behind a function URL. The CSS and JavaScript for
        this page came from S3. CloudFront stitched the two together — all from{' '}
        <code>terraform apply</code>, on a laptop.
      </p>

      <dl>
        <dt>Function</dt>
        <dd><code>{info.renderedBy}</code></dd>
        <dt>Region</dt>
        <dd><code>{info.region}</code></dd>
        <dt>Node</dt>
        <dd><code>{info.node}</code> · {info.memoryMb} MB</dd>
        <dt>Rendered at</dt>
        <dd><code>{info.renderedAt}</code></dd>
        <dt>Container up since</dt>
        <dd><code>{info.containerStartedAt}</code></dd>
        <dt>Requests this container</dt>
        <dd><strong>{info.invocations}</strong>{info.invocations === 1 ? ' — cold start' : ' — warm'}</dd>
      </dl>

      {/* A plain link, not <Link>: a full reload means a fresh server render. */}
      <p>
        <a href="/">Render again</a>
      </p>
    </main>
  )
}
