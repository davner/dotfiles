import React from "react";
import { MultiSelect } from 'primereact/multiselect';

export default function LoadingDemo() {
    return (
        <div className="card flex justify-content-center">
            <MultiSelect loading placeholder="Loading..." className="w-full md:w-20rem" />
        </div>
    );
}
