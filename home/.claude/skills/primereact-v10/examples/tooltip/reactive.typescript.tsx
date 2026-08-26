import React, { useState } from 'react';
import { Tooltip } from 'primereact/tooltip';
import { Slider } from 'primereact/slider';
import { Knob } from 'primereact/knob';
import { Button } from 'primereact/button';

export default function ReactiveDemo() {
    const [buttonTooltip, setButtonTooltip] = useState<string>('Click to proceed');
    const [knobValue, setKnobValue] = useState<number>(60);
    const [sliderValue, setSliderValue] = useState<number>(20);

    return (
        <div className="card flex flex-wrap align-items-center justify-content-center gap-5">
            <Button type="button" label="Save" icon="pi pi-check" tooltip={buttonTooltip} onClick={() => setButtonTooltip('Completed')} />

            <Tooltip target=".knob" content={`${knobValue}%`} />
            <Knob className="knob" value={knobValue} onChange={(e) => setKnobValue(e.value)} showValue={false} />

            <Tooltip target=".slider>.p-slider-handle" content={`${sliderValue}%`} position="top" event="focus" />
            <Slider className="slider" value={sliderValue} onChange={(e) => setSliderValue(e.value)} style={{ width: '14rem' }} />
        </div>
    );
}
