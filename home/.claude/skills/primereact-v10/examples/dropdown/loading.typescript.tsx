import React from "react";
import { Dropdown } from 'primereact/dropdown';

export default function LoadingDemo() {

    return (
        <div className="card flex justify-content-center">
          <Dropdown loading placeholder="Loading..." className="w-full md:w-14rem" />“
        </div>
    )
}
