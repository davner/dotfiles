import React from "react";
import { CascadeSelect, CascadeSelectChangeEvent } from 'primereact/cascadeselect';

export default function LoadingDemo() {
   
    return (
        <div className="card flex justify-content-center">
            <CascadeSelect loading placeholder="Loading..." className="w-full md:w-14rem" breakpoint="767px" style={{ minWidth: '14rem' }} />        
        </div>
    )
}
