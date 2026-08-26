import React, { useState } from "react";
import { InputSwitch } from "primereact/inputswitch";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputSwitch disabled />
        </div>
    );
}
