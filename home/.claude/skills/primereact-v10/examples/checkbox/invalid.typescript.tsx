import React, { useState } from "react";
import { Checkbox } from "primereact/checkbox";

export default function InvalidDemo() {
    const [checked, setChecked] = useState(false);

    return (
        <div className="card flex justify-content-center">
            <Checkbox invalid={!checked} onChange={(e) => setChecked(e.checked)} checked={checked}></Checkbox>
        </div>
    )
}
