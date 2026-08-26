<InputNumber value={value1} onValueChange={(e: InputNumberValueChangeEvent) => setValue1(e.value)} showButtons mode="currency" currency="USD" />
<InputNumber value={value3} onValueChange={(e: InputNumberValueChangeEvent) => setValue3(e.value)} mode="decimal" showButtons min={0} max={100} />
<InputNumber value={value2} onValueChange={(e: InputNumberValueChangeEvent) => setValue2(e.value)} showButtons buttonLayout="horizontal" step={0.25}
            decrementButtonClassName="p-button-danger" incrementButtonClassName="p-button-success" incrementButtonIcon="pi pi-plus" decrementButtonIcon="pi pi-minus"
            mode="currency" currency="EUR" />
