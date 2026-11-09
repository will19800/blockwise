# Decisions

Record choices not settled by the design document and every intentional deviation.

| Date | Decision | Reason | Status |
| --- | --- | --- | --- |
| 2026-11-07 | Use `blockwise` as the repository name. | It is the working title and repository name in the design. | Accepted |
| 2026-11-07 | Create the GitHub repository as private initially. | Safest default while the portfolio project is being built; visibility can change later. | Accepted |
| 2026-11-08 | Use `com.willchen.Blockwise` as the app bundle identifier. | It is stable, conventional, and can be changed before distribution without affecting the scaffold. | Accepted |
| 2026-11-09 | Use `github.com/will19800/blockwise/Server` as the Go module path. | It matches the repository and the design's `Server/` monorepo directory exactly. | Accepted |
| 2026-11-09 | Listen on port 8080 by default with an environment override. | It is conventional for a containerized HTTP service and keeps local and Compose setup simple. | Accepted |

