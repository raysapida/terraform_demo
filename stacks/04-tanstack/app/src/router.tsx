import { createRouter as createTanStackRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

export function getRouter() {
  const router = createTanStackRouter({
    routeTree,
    scrollRestoration: true,
    // No hover preloading. A preload runs the route loader from the browser,
    // which calls the server function over HTTP — and Floci's CloudFront only
    // proxies GET without a query string to a Lambda origin (docs/FINDINGS.md).
    // Every render in this demo is a full server render instead.
    defaultPreload: false,
  })

  return router
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
