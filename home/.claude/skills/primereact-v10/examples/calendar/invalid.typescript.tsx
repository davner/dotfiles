import React, { useState } from "react";
import { Calendar } from 'primereact/calendar';

export default function InvalidDemo() {
    return (
        <div className="card flex justify-content-center">
            <Calendar invalid/>
        </div>
    )
}
