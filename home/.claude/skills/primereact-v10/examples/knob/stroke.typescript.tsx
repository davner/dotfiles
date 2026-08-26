import React, { useState } from 'react';
import { Knob, KnobChangeEvent } from 'primereact/knob';

export default function StrokeDemo() {
    const [value, setValue] = useState<number>(40);

    return (
        <div className="card flex justify-content-center">
            <Knob value={value} onChange={(e : KnobChangeEvent) => setValue(e.value)} strokeWidth={5} />
        </div>

    )
}
