import React, { useState } from "react";
import { InputSwitch } from "primereact/inputswitch";

export default function InvalidDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputSwitch className="p-invalid" />
        </div>
    );
}
