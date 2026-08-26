import React, { useState } from "react";
import { InputNumber, InputNumberValueChangeEvent } from 'primereact/inputnumber';
import { FloatLabel } from 'primereact/floatlabel';

export default function FloatLabelDemo() {
    const [value, setValue] = useState<number>(151351);

    return (
        <div className="card flex justify-content-center">
            <FloatLabel>
                <InputNumber id="number-input" value={value} onValueChange={(e: InputNumberValueChangeEvent) => setValue(e.value)} />
                <label htmlFor="number-input">Number</label>
            </FloatLabel>
        </div>
    )
}
