import React, { useState } from 'react';
import { InputSwitch } from 'primereact/inputswitch';

export function SpecificityDemo() {
    const [checked, setChecked] = useState(false);
    const css = `
        .my-switch-slider {
            border-radius: 0;
        }

        .my-switch-slider:before {
            border-radius: 0;
        }
    `;

    return (
        <div className="card">
            <InputSwitch
                checked={checked}
                onChange={(e) => setChecked(e.value)}
                pt={{
                    slider: {
                        className: 'my-switch-slider'
                    }
                }}
            />
            <style>{css}</style>
        </div>
    );
}
