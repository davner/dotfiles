import React, { useState } from "react";
import { Calendar } from 'primereact/calendar';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Calendar disabled />
        </div>
    )
}
