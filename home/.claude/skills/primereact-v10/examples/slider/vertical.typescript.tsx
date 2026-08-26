import React, { useState } from "react";
import { Slider, SliderChangeEvent } from "primereact/slider";

export default function VerticalDemo() {
    const [value, setValue] = useState<number>(50);

    return (
        <div className="card flex justify-content-center">
            <Slider value={value} onChange={(e: SliderChangeEvent) => setValue(e.value)} orientation="vertical" className="h-14rem" />
        </div>
    )
}
