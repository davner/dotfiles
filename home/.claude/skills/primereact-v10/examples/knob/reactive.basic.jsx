<Knob value={value} size={150} />
<Button icon="pi pi-plus" onClick={() => setValue(value + 1)} disabled={value === 100} />
<Button icon="pi pi-minus" onClick={() => setValue(value - 1)} disabled={value === 0} />
