import React, { useState } from 'react';
import { Knob, KnobChangeEvent } from 'primereact/knob';

export default function MinMaxDemo() {
    const [value, setValue] = useState<number>(10);

    return (
        <div className="card flex justify-content-center">
            <Knob value={value} onChange={(e : KnobChangeEvent) => setValue(e.value)} min={-50} max={50} />
        </div>
    )
}
