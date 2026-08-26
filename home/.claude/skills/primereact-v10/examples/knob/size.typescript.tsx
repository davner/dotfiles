import React, { useState } from 'react';
import { Knob, KnobChangeEvent } from 'primereact/knob';

export default function SizeDemo() {
    const [value, setValue] = useState<number>(60);

    return (
        <div className="card flex justify-content-center">
            <Knob value={value} onChange={(e : KnobChangeEvent) => setValue(e.value)} size={200} />
        </div>
    )
}
