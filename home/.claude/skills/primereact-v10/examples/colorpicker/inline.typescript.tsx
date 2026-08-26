import React, { useState } from "react";
import { ColorPicker, ColorPickerChangeEvent } from 'primereact/colorpicker';

export default function InlineDemo() {
    const [color, setColor] = useState<string>(null);

    return (
        <div className="card flex justify-content-center">
            <ColorPicker value={color} onChange={(e: ColorPickerChangeEvent) => setColor(e.value)} inline />
        </div>
    )
}
