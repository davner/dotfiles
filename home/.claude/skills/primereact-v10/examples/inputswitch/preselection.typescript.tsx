import React, { useState } from "react";
import { InputSwitch, InputSwitchChangeEvent } from "primereact/inputswitch";

export default function PreselectionDemo() {
    const [checked, setChecked] = useState<boolean>(true);

    return (
        <div className="card flex justify-content-center">
            <InputSwitch checked={checked} onChange={(e: InputSwitchChangeEvent) => setChecked(e.value)} />
        </div>
    );
}
