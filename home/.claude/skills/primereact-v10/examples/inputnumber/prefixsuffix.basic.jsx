<InputNumber value={value1} onValueChange={(e) => setValue1(e.value)} suffix=" mi" />
<InputNumber value={value2} onValueChange={(e) => setValue2(e.value)} prefix="%" />
<InputNumber value={value3} onValueChange={(e) => setValue3(e.value)} prefix="Expires in " suffix=" days" />
<InputNumber value={value4} onValueChange={(e) => setValue4(e.value)} prefix="&uarr; " suffix="℃" min={0} max={40} />
