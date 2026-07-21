import { EditorState, Extension, Transaction } from '@codemirror/state';
import { EditorView, scrollPastEnd } from '@codemirror/view';

export function typewriterScroll(): Extension {
	return [scrollPastEnd(), EditorState.transactionExtender.of(centerCursor)];
}

function centerCursor(tr: Transaction) {
	if (!tr.docChanged && !tr.selection) {
		return null;
	}
	if (tr.isUserEvent('select.pointer')) {
		return null;
	}
	return {
		effects: EditorView.scrollIntoView(tr.newSelection.main.head, {
			y: 'center',
		}),
	};
}
