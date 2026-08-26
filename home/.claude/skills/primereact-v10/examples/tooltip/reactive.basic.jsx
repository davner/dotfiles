<Button type="button" label="Save" icon="pi pi-check" tooltip={buttonTooltip} onClick={() => setButtonTooltip('Completed')} />

<Tooltip target=".knob" content={`${knobValue}%`} />
<Knob className="knob" value={knobValue} onChange={(e) => setKnobValue(e.value)} showValue={false} />

<Tooltip target=".slider>.p-slider-handle" content={`${sliderValue}%`} position="top" event="focus" />
<Slider className="slider" value={sliderValue} onChange={(e) => setSliderValue(e.value)} style={{ width: '14rem' }} />
