import React, { useState } from "react";
import { Calendar } from 'primereact/calendar';
import { Nullable } from "primereact/ts-helpers";

export default function IconDemo() {
    const [date, setDate] = useState<Nullable<Date>>(null);

    return (
        <div className="card flex flex-wrap gap-3 p-fluid">
            <div className="flex-auto">
                <label htmlFor="buttondisplay" className="font-bold block mb-2">
                    Button Display
                </label>
                <Calendar id="buttondisplay" value={date} onChange={(e) => setDate(e.value)} showIcon />
            </div>
            <div className="flex-auto">
                <label htmlFor="buttondisplay" className="font-bold block mb-2">
                    Icon Display
                </label>

                <Calendar value={date} onChange={(e) => setDate(e.value)} showIcon  />
            </div>
            <div className="flex-auto">
                <label htmlFor="buttondisplay" className="font-bold block mb-2">
                    Icon Template
                </label>

                <Calendar value={date} onChange={(e) => setDate(e.value)} showIcon timeOnly  icon={() => <i className="pi pi-clock" />} />
            </div>
        </div>
    )
}
