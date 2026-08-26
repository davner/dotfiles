import React, { useState } from "react";
import { Calendar } from 'primereact/calendar';
import { Nullable } from "primereact/ts-helpers";

export default function MultipleDemo() {
    const [dates, setDates] = useState<Nullable<Date[]>>(null);

    return (
        <div className="card flex justify-content-center">
            <Calendar value={dates} onChange={(e) => setDates(e.value)} selectionMode="multiple" readOnlyInput />
        </div>
    )
}
