---
name: frontend-ux
description: Use when building or changing any user-facing screen, list, toggle, table, form, dialog or loading behaviour, or when asked to make an app feel faster or more interactive. Covers designing every state, loading patterns by wait time (skeletons, progress, optimistic UI), preloading and caching data a toggle needs, responsive and density rules, accessibility and Core Web Vitals. Sources are the WeWeb front-end design guide and Smart Interface Design Patterns on loading and progress UX.
---

# Front-end UX baseline

A screen is not done when the ideal state works. It is done when a first-time user
can tell where they are, what to do next, and that the system is responding, in
every state and at every width. Apply this before and after any UI change.

## 1. Design every state

Loading and slow data. Empty results. Failed requests with a way to retry. Invalid
input. Success. Insufficient permission. Partial data (some rows in, more coming).
Name each in the design and test each. A component that only has an ideal state is
unfinished.

Test with realistic content, not placeholders: long customer names, thousands of
rows, missing values. Resize gradually between breakpoints, not only at presets.
Complete the key task with the keyboard alone.

## 2. Loading indicators by expected wait

You usually cannot make a call faster. You can change how long it feels.

| Expected wait | Do this |
|---|---|
| under about 1 s | No indicator. It is not perceived in time and only adds noise. |
| 1 to 3 s | Skeleton screen that matches the real layout. Spinner only for a short, single task. |
| 3 to 10 s | Determinate progress bar showing how much is left. |
| 10 s or more | Progress, a percentage and a status line ("Loaded 1,000 of 3,564"). Let the user keep working. |

Rules that follow:
- Show the indicator where the new content will appear (bottom for "load more", top
  for refresh). Never stack several spinners on one page.
- Delay the skeleton by about 350 ms so fast loads show nothing, and keep it for at
  least about 400 ms once shown so it does not flicker.
- Announce loading to assistive tech once and politely (`aria-busy`, a polite live
  region). Respect `prefers-reduced-motion`.
- Make progress feel quicker at the start and slower toward the end.

## 3. Perceived performance

- Keep users active. Passive waiting is overestimated by about 36%. Give them the
  rows already loaded, a next step, or another part of the app to use.
- Start work early. Waiting to start feels longer than waiting to finish, so begin
  fetching what the user is likely to need before they ask.
- Optimistic UI. Apply the user's action immediately, confirm in the background, and
  roll back with a visible error on that item if it fails. Never lose an action
  silently.
- No queue jumping. Results must not arrive in an order that makes the user doubt
  what happened; a revalidation must not resurrect an item the user just finished
  unless the server says it is still open.
- Users only notice a change in speed of about 20% or more. Shaving 0.2 s off a 5 s
  wait is not worth a feature.
- Move long work to the background and let the user leave.

## 4. Load data deliberately

- If a control toggles between sets of data (money in / money out, tabs, filters),
  load all the sets together and switch instantly. A toggle must make zero requests
  and must never show an empty state for data the screen already had.
- Cache what a screen loaded and reuse it across tabs and remounts: stale while
  revalidate, keyed by the record and a version, cleared on sign-out or when the
  scope changes. Do not throw data away because a component remounted.
- Invalidate after every write path that can change what is shown. A stale row
  shown as still open is worse than a slow page.
- Run independent requests in parallel. Remove waterfalls (A then B then C) unless B
  truly needs A.
- Stream or page big lists, show a determinate "Loaded x of y", never block rows
  that are already on screen.
- Limit what loads and when. Render less at once. Prefer starting a likely next
  fetch to waiting for the click.
- Do not add a data-fetching library to get this; a small cache is enough unless
  the project already uses one.

## 5. Layout, density and language

- Mobile first: decide what matters on the smallest screen, then add value on
  larger ones. Do not shrink a desktop layout.
- Use named design tokens (colour, type scale, spacing, radii, component states)
  and reuse a component only when its purpose and behaviour match.
- One primary action per screen. A selected tab or toggle must not look like the
  primary action.
- Compact by default on desktop (controls about 32 px), 44 px targets on touch.
- Say each thing once: one progress figure, one status per row.
- Plain words an owner would use. Every dialog has a close icon, Escape, and
  returns focus to what opened it.
- Every screen answers: where am I, what is the next step, and what happens when I
  press this.

## 6. Accessibility

Native HTML controls first; add ARIA only for missing information (a role does not
add keyboard behaviour). Everything reachable and operable by keyboard with visible
focus and no traps. Labels tied to inputs, clear error text. Contrast at least
4.5:1 for text and distinguishable controls and focus rings. Test beyond the
checklist: enlarged text, keyboard-only, a screen reader.

## 7. Performance and measurement

Optimise images, minify, cache static assets, use a CDN. Judge speed on real
visits, not your own machine: Core Web Vitals at the 75th percentile, mobile and
desktop separately. Targets: LCP 2.5 s or less, INP 200 ms or less, CLS 0.1 or
less. A single lab run diagnoses; it does not represent users. Throttle the
network and the API when testing loading states.

## 8. Working with AI-built UI

Give the agent the design tokens, existing components, responsive rules,
accessibility requirements, state conventions and approved examples, in a file such
as `design.md`. Review generated UI at several widths, with realistic data, with
every state, and against the design system, as you would any front end. Run the
browser smoke test as part of the one verification command, not only in CI.

## Quick review checklist

1. Every state designed and tried (loading, empty, error, success, partial)?
2. Wait under 1 s shows nothing; 1 to 3 s a skeleton; longer has progress and status?
3. Toggles and tabs switch with zero requests and no empty flash?
4. Actions apply optimistically and roll back visibly?
5. Independent requests in parallel; no remount that refetches?
6. One primary action, plain words, one source for each number?
7. Keyboard, focus, contrast, reduced motion, 44 px on touch?
8. Checked between breakpoints with long real content?

## Sources

- WeWeb, Front-End Design Principles: https://www.weweb.io/blog/front-end-design-guide
- Smart Interface Design Patterns, Designing Better Loading and Progress UX:
  https://smart-interface-design-patterns.com/articles/designing-better-loading-progress-ux/
