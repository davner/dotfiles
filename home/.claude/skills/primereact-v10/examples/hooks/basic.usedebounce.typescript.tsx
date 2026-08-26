import React from 'react'; 
import { InputText } from 'primereact/inputtext';
import { useDebounce } from 'primereact/hooks';

export default function BasicDemo() {
    const [inputValue, debouncedValue, setInputValue] = useDebounce('', 400);

    return (
        <div className="card flex flex-column align-items-center gap-3">
            <InputText type="text" value={inputValue} onChange={(e) => setInputValue(e.target.value)} />
            <span className="text-xl">
                Debounced Value: <strong>{debouncedValue}</strong>
            </span>
        </div>
    )
}
