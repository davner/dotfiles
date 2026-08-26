import React, { useState } from 'react';
import { InputOtp } from 'primereact/inputotp';

export default function MaskDemo() {
    const [token, setTokens] = useState<string | number | undefined>();

    return (
        <div className="card flex justify-content-center">
            <InputOtp value={token} onChange={(e) => setTokens(e.value)} mask/>
        </div>
    );
}
