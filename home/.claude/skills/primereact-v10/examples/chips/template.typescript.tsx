import React, { useState } from "react";
import { Chips, ChipsChangeEvent } from "primereact/chips";

export default function TemplateDemo() {
    const [value, setValue] = useState<string[]>([]);
    const customChip = (item: string) => {
        return (
            <div>
                <span>{item} - (active)</span>
                <i className="pi pi-user-plus"></i>
            </div>
        );
    };

    return (
        <div className="card p-fluid">
            <Chips value={value} onChange={(e: ChipsChangeEvent) => setValue(e.value)} itemTemplate={customChip} />
        </div>
    )
}
