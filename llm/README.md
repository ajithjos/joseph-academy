# Cornerstone LLM Background Pack

This directory is background, not a rigid prompt system.

Use it when you want to give an LLM enough product context and behavioral guidance without restating Cornerstone from scratch each time.

## What To Attach

Attach this directory, or at minimum:

- `00-cornerstone-curriculum-prompt.md`
- optional notes from `10-subject-area-brief-template.md`
- any existing `content/catalog/*.yaml` files that the work must align with
- any existing `content/materials/**/*.md` files that should be reused, revised, or kept consistent

## How To Use It

Put the real request in the question or chat itself. Say plainly:

- what you want generated, revised, or reviewed
- which subject and area are in scope
- which files may change
- which files must stay fixed
- any special constraints for this slice

No separate generation or review template is required.

## Files In This Directory

- `00-cornerstone-curriculum-prompt.md`: product background, vocabulary, delivery model, and writing behavior
- `10-subject-area-brief-template.md`: optional background notes for one subject-area slice