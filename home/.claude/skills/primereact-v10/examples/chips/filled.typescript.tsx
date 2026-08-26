import React, { useState } from "react";
import { Chips, ChipsChangeEvent } from "primereact/chips";

export default function FilledDemo() {
    const [value, setValue] = useState<string[]>([]);

    return (
        <div className="card p-fluid">
            <Chips variant="filled" value={value} onChange={(e: ChipsChangeEvent) => setValue(e.value)} />
        </div>
    )
}
