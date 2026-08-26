import React, { useState } from "react";
import { InputMask, InputMaskChangeEvent } from "primereact/inputmask";
import { FloatLabel } from "primereact/floatlabel";

export default function FloatLabelDemo() {
    const [value, setValue] = useState<string | undefined>();

    return (
        <div className="card flex justify-content-center">
            <FloatLabel>
                <InputMask id="ssn_input" value={value} onChange={(e: InputMaskChangeEvent) => setValue(e.target.value)} mask="999-99-9999" />
                <label htmlFor="ssn_input">SSN</label>
            </FloatLabel>
        </div>
    )
}
