import React, { useState } from "react";
import { Calendar } from 'primereact/calendar';
import { FloatLabel } from 'primereact/floatlabel';
import { Nullable } from "primereact/ts-helpers";

export default function FloatLabelDemo() {
    const [date, setDate] = useState<Nullable<Date>>(null);

    return (
        <div className="card flex justify-content-center">
            <FloatLabel>
                <Calendar inputId="birth_date" value={date} onChange={(e) => setDate(e.value)} />
                <label htmlFor="birth_date">Birth Date</label>
            </FloatLabel>
        </div>
    )
}
