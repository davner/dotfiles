import React, { useRef } from 'react';
import { StyleClass } from 'primereact/styleclass';
import { Button } from 'primereact/button';
import { InputText } from 'primereact/inputtext';

export default function ToggleClassDoc() {
    const toggleBtnRef = useRef<Button>(null);

    return (
        <div className="card flex flex-column align-items-center gap-3">
            <StyleClass nodeRef={toggleBtnRef} selector="@next" toggleClassName="p-disabled" />
            <Button ref={toggleBtnRef} label="Toggle p-disabled" />
            <InputText />
        </div>
    );
}
