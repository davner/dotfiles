import React, { useState } from "react";
import { MultiSelect } from 'primereact/multiselect';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <MultiSelect disabled placeholder="Select Cities" className="w-full md:w-20rem" />
        </div>
    );
}
