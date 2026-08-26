import React, { useState } from "react";
import { Checkbox } from "primereact/checkbox";

export default function FilledDemo() {
    const [checked, setChecked] = useState<boolean>(false);

    return (
        <div className="card flex justify-content-center">
            <Checkbox variant="filled" onChange={e => setChecked(e.checked)} checked={checked}></Checkbox>
        </div>
    )
}
