# Task Documentation: Fix chunk-resume corruption in ModelDownloadManager

- Task ID: `01KZYQZG1QD1NPHVB26N4NWCMX`
- Status: in_progress
- Priority: high
- Complexity: moderate
- Research Ready: yes
- Created At: 2026-08-13T23:40:35.766Z
- Updated At: 2026-08-13T23:40:49.580Z

## Current Focus

Not set.

## Research

### context
- **context**: downloadChunkWithRetry captures chunk.state once from an immutable Chunk struct. On retry after a mid-chunk failure, resumeOffset is stale while OutputStream appends at the current on-disk length -> misaligned writes -> oversized chunk -> loadExistingChunks deletes it -> permanent "Some download chunks did not complete." because .part dir is kept with same stale logic. Single-stream resume also breaks if a ranged resume gets a 200 (whole body appended at wrong offset).

### files
- **files**: TheBlackArchives/Services/ModelDownloadManager.swift only. downloadWithParallelChunks, downloadChunkWithRetry, downloadChunk, downloadWithSingleStream. No other files need changes for fix 1.

### requirements
- **requirements**: Acceptance: (a) resume offset derived from real on-disk chunk size at start of each attempt, never stale snapshot; (b) oversized/corrupt chunk files reset to re-download cleanly; (c) ranged chunk requests must get 206 (reject 200 whole-body); (d) truncated bodies detected via exact byte-count match so retry self-heals; (e) stale .part temp dirs (changed URL/fileSize/concurrency) wiped via layout marker so bytes from two downloads never splice; (f) merged file size verified == remote size; (g) single-stream ranged resume that gets 200 truncates and restarts. Preserve existing resume-across-launch behavior for same-layout partials.

## Recent Events

- 2026-08-13T23:40:49.581Z task_claimed
- 2026-08-13T23:40:46.708Z task_updated
- 2026-08-13T23:40:35.771Z task_created {"title":"Fix chunk-resume corruption in ModelDownloadManager","complexity":"moderate"}

---

_Generated at 2026-08-13T23:40:49.628Z by Agent Orchestration._