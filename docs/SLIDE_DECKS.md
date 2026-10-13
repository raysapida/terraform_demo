# Main slide deck

Edit [slides.md](slides.md), then run `make pptx` from the repository root to
rebuild both [slides.html](slides.html) and [slides.pptx](slides.pptx).
`make slides` builds only HTML. Python 3 builds HTML; Node/npm build PowerPoint.
The first PowerPoint build installs the pinned dependencies in `scripts/pptx/`.

This standalone repository contains only the improved main deck: 48 main slides
and one Q&A backup. It keeps the seven-slide deployment story, four app examples,
two DNS slides, and the shared-connection diagram before the ownership exercise.
There are no dated deck snapshots or deployment-only presentation here.

## Rehearsal budget

Budget **50–60 minutes before Q&A**, with images and dependencies already
downloaded. This is an estimate, not a measured presentation time. Audience setup
and troubleshooting are outside the estimate.

| Material | Slides | Target minutes |
|---|---|---:|
| Welcome, background, optional setup | 1–3 | 2 |
| Deployment story | 4–10 | 7 |
| Two axes, Floci, app roadmap, state | 11–14 | 4 |
| Static site | 15–22 | 6 |
| Lambda | 23–28 | 7 |
| Rails | 29–34 | 10 |
| TanStack Start | 35–39 | 6 |
| Four-stack comparison | 40–41 | 2 |
| DNS | 42–43 | 2 |
| Shared-connection diagram, ownership failure and fix | 44–46 | 7 |
| Takeaways and repository | 47–48 | 2 |
| **Total target** | | **55** |

Run the static-site demo once; its final slide explains the provision/deploy
split using that run. Keep optional inspections and detailed emulator caveats in
the notes if time is tight. The ownership exercise lives under
`stacks/05-shared-ownership/`; make broken/order/fixed run it in teaching order.
Do not apply its fixed network before the plan-time failure demonstration.
