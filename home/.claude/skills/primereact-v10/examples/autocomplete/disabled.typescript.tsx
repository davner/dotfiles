import React from "react";
import { AutoComplete } from "primereact/autocomplete";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <AutoComplete disabled placeholder="Disabled" />
        </div>
    )
}
