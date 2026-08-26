import React from "react";
import { Editor } from "primereact/editor";

export default function ReadOnlyDemo() {
    return (
        <div className="card">
            <Editor value="Always bet on Prime!" readOnly style={{ height: '320px' }} />
        </div>    
    )
}
