import React, { useState } from "react";
import { InputMask, InputMaskChangeEvent} from "primereact/inputmask";

export default function OptionalDemo() {
    const [value, setValue] = useState<string | undefined>();

    return (
        <div className="card flex justify-content-center">
            <InputMask value={value} onChange={(e: InputMaskChangeEvent) => setValue(e.target.value)} mask="(999) 999-9999? x99999" placeholder="(999) 999-9999? x99999" />
        </div>
    )
}
