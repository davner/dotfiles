import React, { useState } from "react";
import { Chips, ChipsChangeEvent } from "primereact/chips";

export default function InvalidDemo() {
    const [value, setValue] = useState<string[]>([]);

    return (
        <div className="card p-fluid">
            <Chips invalid value={value} onChange={(e: ChipsChangeEvent) => setValue(e.value)} />
        </div>
    )
}
