<InputText type="text" value={inputValue} onChange={(e) => setInputValue(e.target.value)} />
<span className="text-xl">
    Debounced Value: <strong>{debouncedValue}</strong>
</span>
