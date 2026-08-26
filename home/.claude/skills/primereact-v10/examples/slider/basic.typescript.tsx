import React, { useState } from "react";
import { Slider, SliderChangeEvent } from "primereact/slider";

export default function BasicDemo() {
    const [value, setValue] = useState<number>(null);

    return (
        <div className="card flex justify-content-center">
            <Slider value={value} onChange={(e: SliderChangeEvent) => setValue(e.value)} className="w-14rem" />
        </div>
    )
}
