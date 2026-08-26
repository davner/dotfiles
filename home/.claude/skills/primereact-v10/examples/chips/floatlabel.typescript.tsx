import React, { useState } from "react";
import { Chips, ChipsChangeEvent } from "primereact/chips";
import { FloatLabel } from "primereact/floatlabel";

export default function FloatLabelDemo() {
    const [value, setValue] = useState<string[]>([]);

    return (
        <div className="card p-fluid">
            <FloatLabel>
                <Chips id="username" value={value} onChange={(e: ChipsChangeEvent) => setValue(e.value)} />
                <label htmlFor="username">Username</label>
            </FloatLabel>
        </div>
    )
}
