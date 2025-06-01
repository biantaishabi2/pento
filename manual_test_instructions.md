# Manual Test Instructions for Piece Removal

## Current Status

Based on the investigation:

1. **The remove_piece functionality works correctly** - both the Game logic and LiveView event handlers are properly implemented
2. **The issue is that pieces aren't being placed in the first place** - the server logs show `placed_pieces: []` is always empty

## How to Test

1. Open the browser console (F12)
2. Go to the game at http://localhost:4000
3. Click on a piece in the palette (e.g., the "T" piece)
4. You should see:
   - The piece becomes highlighted
   - Green valid positions appear on the board
   - Control buttons (Rotate, Flip) appear

5. Click on a green highlighted cell on the board
6. Check the browser console for any JavaScript errors
7. Check if the "Debug: 已放置的方块" section appears with a "移除 T" button

## What's Happening

- When you click on a piece in the palette, it triggers `select_piece` event
- When you click on the board while dragging, it should trigger either:
  - `drop_at_cell` event (when clicking on a specific cell)
  - `drop_piece` event (when releasing the mouse)

## Debug Steps

1. Check if the piece is actually being placed:
   - Look for the debug section that shows placed pieces
   - If it doesn't appear, pieces aren't being placed

2. Check server logs:
   - Look for "drop_at_cell event" or "drop_piece event" messages
   - Look for "Successfully placed piece" messages

3. If pieces are placed but can't be removed:
   - Click on the debug "移除 X" button first
   - If that works, the issue is with SVG event propagation
   - If that doesn't work, check for JavaScript errors

## Common Issues

1. **SVG Event Propagation**: Sometimes SVG elements don't properly propagate click events
2. **Dragging State**: The code prevents removal while dragging to avoid accidental removes
3. **Empty Placed Pieces**: The most likely issue - pieces aren't being placed at all