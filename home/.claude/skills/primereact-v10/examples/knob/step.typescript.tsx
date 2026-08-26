import React, { useState } from 'react';
import { Knob, KnobChangeEvent } from 'primereact/knob';

export default function StepDemo() {
    const [value, setValue] = useState<number>(10);

    return (
        <div className="card flex justify-content-center">
            <Knob value={value} step={10} onChange={(e : KnobChangeEvent) => setValue(e.value)}  />
        </div>
    )
}
