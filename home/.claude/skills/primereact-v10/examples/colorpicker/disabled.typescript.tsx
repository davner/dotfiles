import React from "react";
import { ColorPicker } from 'primereact/colorpicker';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <ColorPicker disabled />
        </div>
    )
}
