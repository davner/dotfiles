<div className="p-inputgroup flex-1">
    <InputText placeholder="Price" />
    <span className="p-inputgroup-addon">
        <RadioButton name="rb1" value="rb1" checked={radioValue === 'rb1'} onChange={(e) => setRadioValue(e.value)} />
    </span>
</div>

<div className="p-inputgroup flex-1">
    <span className="p-inputgroup-addon">
        <Checkbox checked={checked1} onChange={(e) => setChecked1(!checked1)} />
    </span>
    <InputText placeholder="Username" />
</div>

<div className="p-inputgroup flex-1">
    <span className="p-inputgroup-addon">
        <Checkbox checked={checked2} onChange={(e) => setChecked2(!checked2)} />
    </span>
    <InputText placeholder="Website" />
    <span className="p-inputgroup-addon">
        <RadioButton name="rb2" value="rb2" checked={radioValue === 'rb2'} onChange={(e) => setRadioValue(e.value)} />
    </span>
</div>
