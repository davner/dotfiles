import React, { useState } from "react";
import { Dropdown } from 'primereact/dropdown';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Dropdown disabled placeholder="Select a City" className="w-full md:w-14rem" />
        </div>
    )
}
