import React, { useState } from "react";
import { ToggleButton, ToggleButtonChangeEvent } from 'primereact/togglebutton';

export default function DisabledDemo() {
    const [checked, setChecked] = useState<boolean>(false);

    return (
        <div className="card flex justify-content-center">
            <ToggleButton disabled checked={checked} onChange={(e: ToggleButtonChangeEvent) => setChecked(e.value)} className="w-8rem" />
        </div>
    );
}
