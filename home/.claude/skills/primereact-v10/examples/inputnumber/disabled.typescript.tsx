import React, { useState } from "react";
import { InputNumber } from 'primereact/inputnumber';

export default function DisabledDemo() {
    const [value, setValue] = useState<number>(50);

    return (
        <div className="card flex justify-content-center">
            <InputNumber value={value} disabled prefix="%" />
        </div>
    )
}
