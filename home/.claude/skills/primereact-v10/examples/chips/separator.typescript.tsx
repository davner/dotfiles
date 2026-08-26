import React, { useState } from "react";
import { Chips, ChipsChangeEvent } from "primereact/chips";

export default function SeparatorDemo() {
    const [value, setValue] = useState<string[]>([]);

    return (
        <div className="card p-fluid">
            <Chips value={value} onChange={(e: ChipsChangeEvent) => setValue(e.value)} separator="," />
        </div>
    )
}
