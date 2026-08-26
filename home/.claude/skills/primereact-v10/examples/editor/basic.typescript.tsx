import React, { useState } from "react";
import { Editor, EditorTextChangeEvent } from "primereact/editor";

export default function BasicDemo() {
    const [text, setText] = useState<string>('');

    return (
        <div className="card">
            <Editor value={text} onTextChange={(e: EditorTextChangeEvent) => setText(e.htmlValue)} style={{ height: '320px' }} />
        </div>
    )
}
