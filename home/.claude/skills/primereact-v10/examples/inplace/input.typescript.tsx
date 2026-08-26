import React, { useState } from 'react';
import { Inplace, InplaceDisplay, InplaceContent } from 'primereact/inplace';
import { InputText } from 'primereact/inputtext';

export default function InputDemo() {
    const [text, setText] = useState<string>('');

    return (
        <div className="card">
            <Inplace closable>
                <InplaceDisplay>{text || 'Click to Edit'}</InplaceDisplay>
                <InplaceContent>
                    <InputText value={text} onChange={(e) => setText(e.target.value)} autoFocus />
                </InplaceContent>
            </Inplace>
        </div>
    );
}
