import React, { useState }  from 'react'; 
import { InputText } from 'primereact/inputtext';

export default function RegexDemo() {
    const [prevValue, setPrevValue] = useState('');

    const validateInput = (event: React.FormEvent<HTMLInputElement>, validatePattern: boolean) => {
        const target = event.target as HTMLInputElement;

        // validated is the result of the regex against the whole input string
        if (validatePattern) {
            if (target.value.length > 0) {
                setPrevValue(target.value);
            }

        // key was OK so do nothing
        return;
        }

        // key made the whole input not valid so block this key
        //  Compare current value with previous value
        if (target.value.length > 0) {
            // Set previous valid value
            target.value = prevValue;
        }
    };

    return (
        <div className="card flex justify-content-center">
            <div>
                <label htmlFor="numkeys" className="font-bold block mb-2">
                    Block Numeric (allow "+" only once at start)
                </label>
                <InputText id="numkeys" keyfilter={/^[+]?(\d{1,12})?$/} validateOnly onInput={validateInput} />
            </div>
        </div>
    )
}
