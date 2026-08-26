import React, { useState } from "react";
import { Password } from 'primereact/password';
import { FloatLabel } from 'primereact/floatlabel';

export default function FloatLabelDemo() {
    const [value, setValue] = useState<string>('');

    return (
        <div className="card flex justify-content-center">
            <FloatLabel>
                <Password inputId="password" value={value} onChange={(e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value)} />
                <label htmlFor="password">Password</label>
            </FloatLabel>
        </div>
    )
}
