import React from 'react'; 
import { InputTextarea } from "primereact/inputtextarea";

export default function KeyFilterDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputTextarea keyfilter="int" placeholder="Integers" rows={5} cols={30}/>
        </div>
    )
}
