import React, { useState } from "react";
import { Editor, EditorTextChangeEvent } from "primereact/editor";

export default function TemplateDemo() {
    const [text, setText] = useState<string>('<div>Hello World!</div><div>PrimeReact <b>Editor</b> Rocks</div><div><br></div>');

    const renderHeader = () => {
        return (
            <span className="ql-formats">
                <button className="ql-bold" aria-label="Bold"></button>
                <button className="ql-italic" aria-label="Italic"></button>
                <button className="ql-underline" aria-label="Underline"></button>
            </span>
        );
    };

    const header = renderHeader();

    return (
        <div className="card">
            <Editor value={text} onTextChange={(e: EditorTextChangeEvent) => setText(e.htmlValue)} headerTemplate={header} style={{ height: '320px' }} />
        </div>
    )
}
