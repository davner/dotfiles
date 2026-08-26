<InputNumber value={value1} onValueChange={(e) => setValue1(e.value)} />
<InputNumber value={value2} onValueChange={(e) => setValue2(e.value)} useGrouping={false} />
<InputNumber value={value3} onValueChange={(e) => setValue3(e.value)} minFractionDigits={2} maxFractionDigits={5} />
<InputNumber value={value4} onValueChange={(e) => setValue4(e.value)} min={0} max={100} />
