import { Editor, Extension } from '@tiptap/core'
import { Document } from '@tiptap/extension-document'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Image from '@tiptap/extension-image'
import Placeholder from '@tiptap/extension-placeholder'
import Link from '@tiptap/extension-link'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import CharacterCount from '@tiptap/extension-character-count'
import TextDirection from 'tiptap-text-direction'
import { Footnote, FootnoteReference, Footnotes } from 'tiptap-footnotes'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { DecorationSet, Decoration } from '@tiptap/pm/view'

// ── Swift bridge ──────────────────────────────────────────────────────────

function post(msg) {
  const h = window.webkit?.messageHandlers?.editorBridge
  if (h) h.postMessage(msg)
}

// ── Astigmatism mode (ProseMirror decoration plugin) ──────────────────────
//
// Decorations are ProseMirror-managed: they update automatically on every
// state transaction (including selection changes) without any manual event
// wiring, and they don't interfere with ProseMirror's own MutationObserver.

let astigMode = false
let contentReady = false
const astigKey = new PluginKey('astigFocus')

const AstigFocusExtension = Extension.create({
  name: 'astigFocus',
  addProseMirrorPlugins() {
    return [new Plugin({
      key: astigKey,
      state: {
        init: () => false,
        apply(tr, prev) {
          const meta = tr.getMeta(astigKey)
          return meta !== undefined ? meta : prev
        },
      },
      props: {
        decorations(state) {
          if (!astigKey.getState(state)) return DecorationSet.empty
          const { $head } = state.selection
          if ($head.depth < 1) return DecorationSet.empty

          const node1 = $head.node(1)
          const isList = node1 && (
            node1.type.name === 'bulletList' ||
            node1.type.name === 'orderedList' ||
            node1.type.name === 'taskList' ||
            node1.type.name === 'footnotes'
          )

          let from, to
          if (isList && $head.depth >= 2) {
            from = $head.before(2)
            to   = $head.after(2)
          } else {
            from = $head.before(1)
            to   = $head.after(1)
          }

          return DecorationSet.create(state.doc, [
            Decoration.node(from, to, { class: 'astig-focus' }),
          ])
        },
      },
    })]
  },
})

// ── Editor ────────────────────────────────────────────────────────────────

const editor = new Editor({
  element: document.getElementById('editor'),
  extensions: [
    // Custom Document schema allows a footnotes node at the end
    Document.extend({ content: 'block+ footnotes?' }),
    StarterKit.configure({
      document: false,
      heading: { levels: [1, 2, 3] },
    }),
    Underline,
    Image.configure({ inline: false }),
    Placeholder.configure({ placeholder: '' }),
    Link.configure({ openOnClick: false }),
    TaskList,
    TaskItem.configure({ nested: true }),
    CharacterCount,
    TextDirection,
    Footnote,
    FootnoteReference,
    Footnotes,
    AstigFocusExtension,
  ],
  onUpdate() {
    post({ type: 'documentChanged' })
    sendStateUpdate()
    requestAnimationFrame(doCenteredScroll)
    updateCursor()
  },
  onSelectionUpdate() {
    sendStateUpdate()
    updateCursor()
  },
  onFocus() {
    updateCursor()
  },
  onBlur() {
    updateCursor()
  },
  onCreate() {
    post({ type: 'editorReady' })
    if (window.__ft_astig) {
      astigMode = true
      document.body.classList.add('astig-mode')
      // Don't dispatch yet — wait for setContent so the decoration
      // doesn't appear on the blank pre-load state.
    }
  },
})

window.editor = editor

// ── State updates → Swift ─────────────────────────────────────────────────

function sendStateUpdate() {
  post({
    type: 'stateUpdate',
    bold:        editor.isActive('bold'),
    italic:      editor.isActive('italic'),
    underline:   editor.isActive('underline'),
    heading:     editor.isActive('heading', { level: 1 }) ? 1
               : editor.isActive('heading', { level: 2 }) ? 2
               : editor.isActive('heading', { level: 3 }) ? 3 : 0,
    bulletList:  editor.isActive('bulletList'),
    orderedList: editor.isActive('orderedList'),
    blockquote:  editor.isActive('blockquote'),
  })
}

// ── Custom cursor ─────────────────────────────────────────────────────────

const cur = document.createElement('div')
cur.id = 'custom-cursor'
document.getElementById('editor').appendChild(cur)

function updateCursor() {
  if (!editor.isFocused || !editor.state.selection.empty) {
    cur.style.display = 'none'
    return
  }
  const pos = editor.state.selection.$head.pos
  try {
    const coords  = editor.view.coordsAtPos(pos)
    const domPos  = editor.view.domAtPos(pos)
    let node      = domPos.node
    if (node.nodeType === 3) node = node.parentElement
    const style   = getComputedStyle(node)
    const fontSize  = parseFloat(style.fontSize) || 22
    const cursorH   = fontSize * 1.5
    const charH     = coords.bottom - coords.top
    const ed        = document.getElementById('editor')
    const edRect    = ed.getBoundingClientRect()
    const textCenter = coords.top + (charH / 2) - edRect.top + ed.scrollTop
    const top  = textCenter - (cursorH / 2)
    const left = coords.left - edRect.left
    cur.style.top    = top + 'px'
    cur.style.left   = left + 'px'
    cur.style.height = cursorH + 'px'
    cur.style.display = 'block'
    cur.classList.remove('blinking')
    void cur.offsetWidth  // force reflow to restart animation
    cur.classList.add('blinking')
  } catch {
    cur.style.display = 'none'
  }
}

// ── Auto-scroll (centered mode) ───────────────────────────────────────────

let autoScrollMode = 'regular'

function doCenteredScroll() {
  if (autoScrollMode !== 'centered') return
  const sel = window.getSelection()
  if (!sel || sel.rangeCount === 0) return
  const range = sel.getRangeAt(0)
  const rect  = range.getBoundingClientRect()
  if (rect.height === 0) return
  const ed        = document.getElementById('editor')
  const edRect    = ed.getBoundingClientRect()
  const cursorCenterY = rect.top + rect.height / 2
  const edCenterY     = edRect.top + ed.clientHeight / 2
  if (cursorCenterY <= edCenterY) return
  const targetScroll = ed.scrollTop + (cursorCenterY - edCenterY)
  ed.scrollTo({ top: Math.max(0, targetScroll), behavior: 'smooth' })
}

// ── Footnote tooltip ──────────────────────────────────────────────────────

const tooltip = document.getElementById('footnote-tooltip')

function getFootnoteText(id) {
  let text = null
  editor.state.doc.descendants(node => {
    if (node.type.name === 'footnote' &&
        (node.attrs.id === id || node.attrs['data-id'] === id || node.attrs['footnote-id'] === id)) {
      text = node.textContent
      return false
    }
  })
  return text
}

editor.view.dom.addEventListener('mouseover', e => {
  const ref = e.target.closest('[data-type="footnoteReference"]')
  if (!ref) { tooltip.hidden = true; return }
  const id = ref.getAttribute('data-id') || ref.getAttribute('data-footnote-id') || ref.getAttribute('data-footnote')
  const text = id ? getFootnoteText(id) : null
  if (!text) { tooltip.hidden = true; return }
  tooltip.textContent = text
  tooltip.hidden = false
  const refRect = ref.getBoundingClientRect()
  tooltip.style.left = refRect.left + 'px'
  tooltip.style.top  = (refRect.bottom + 6) + 'px'
})

editor.view.dom.addEventListener('mouseout', e => {
  if (!e.target.closest('[data-type="footnoteReference"]')) return
  tooltip.hidden = true
})

// Footnote reference click → scroll to corresponding footnote body
editor.view.dom.addEventListener('click', e => {
  const ref = e.target.closest('[data-type="footnoteReference"]')
  if (!ref) return
  const id = ref.getAttribute('data-id') || ref.getAttribute('data-footnote-id') || ref.getAttribute('data-footnote')
  if (!id) return
  const target = document.querySelector(`[data-type="footnote"][data-id="${id}"]`)
            || document.querySelector(`[data-type="footnote"][data-footnote-id="${id}"]`)
            || document.querySelector(`[data-footnote-id="${id}"]`)
  target?.scrollIntoView({ behavior: 'smooth', block: 'center' })
})

// ── window.editorBridge (called from Swift via evaluateJavaScript) ─────────

window.editorBridge = {
  setContent(n) {
    const doc = typeof n === 'string' ? JSON.parse(n) : n
    editor.commands.setContent(doc, false)
    if (!contentReady) {
      contentReady = true
      if (astigMode) {
        editor.view.dispatch(editor.state.tr.setMeta(astigKey, true))
      }
    }
  },
  toggleBold()        { editor.chain().focus().toggleBold().run();        sendStateUpdate() },
  toggleItalic()      { editor.chain().focus().toggleItalic().run();      sendStateUpdate() },
  toggleUnderline()   { editor.chain().focus().toggleUnderline().run();   sendStateUpdate() },
  toggleBlockquote()  { editor.chain().focus().toggleBlockquote().run();  sendStateUpdate() },
  toggleBulletList()  { editor.chain().focus().toggleBulletList().run();  sendStateUpdate() },
  toggleOrderedList() { editor.chain().focus().toggleOrderedList().run(); sendStateUpdate() },
  setHeading(level) {
    if (level === 0) editor.chain().focus().setParagraph().run()
    else editor.chain().focus().setHeading({ level }).run()
    sendStateUpdate()
  },
  addFootnoteReference() { editor.chain().focus().addFootnote().run() },
  copyAll() {
    post({ type: 'copyAll', text: editor.getText(), html: editor.getHTML() })
  },
  focus() { editor.commands.focus('end') },
  setAutoScrollMode(m) {
    autoScrollMode = m
    const ed = document.getElementById('editor')
    ed.style.paddingBottom = m === 'centered' ? '50vh' : ''
  },
  insertImage(src) {
    editor.chain().focus().insertContent({ type: 'image', attrs: { src, alt: '' } }).run()
  },
  setAstigMode(enabled) {
    astigMode = enabled
    if (enabled) {
      document.body.classList.add('astig-mode')
    } else {
      document.body.classList.remove('astig-mode')
    }
    if (contentReady) {
      editor.view.dispatch(editor.state.tr.setMeta(astigKey, enabled))
    }
  },
}
