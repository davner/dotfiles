import React from "react";
import { Password } from 'primereact/password';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Password disabled placeholder="Disabled" />
        </div>
    )
}
