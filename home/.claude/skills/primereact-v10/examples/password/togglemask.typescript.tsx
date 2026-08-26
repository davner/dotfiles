import React, { useState } from "react";
import { Password } from 'primereact/password';

export default function ToggleMaskDemo() {
    const [value, setValue] = useState<string>('');

    return (
        <div className="card flex justify-content-center">
            <Password value={value} onChange={(e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value)} toggleMask />
        </div>
    )
}
