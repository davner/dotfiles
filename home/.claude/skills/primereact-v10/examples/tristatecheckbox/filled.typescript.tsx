import React, { useState } from "react";
import { TriStateCheckbox, TriStateCheckboxChangeEvent } from 'primereact/tristatecheckbox';

export default function FilledDemo() {
    const [value, setValue] = useState<boolean | undefined | null>(null);

    return (
        <div className="card flex flex-column align-items-center gap-3">
            <TriStateCheckbox variant="filled" value={value} onChange={(e : TriStateCheckboxChangeEvent) => setValue(e.value)} />
        </div>
    );
}
