import React from "react";
import { Mention } from 'primereact/mention';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Mention disabled />
        </div>
    )
}
