import React, { useState } from "react";
import { InputMask } from "primereact/inputmask";

export default function MaskDemo() {
    return (
        <div className="card p-fluid flex flex-wrap gap-3">
            <div className="flex-auto">
                <label htmlFor="ssn" className="font-bold block mb-2">SSN</label>
                <InputMask id="ssn" mask="999-99-9999" placeholder="999-99-9999"></InputMask>
            </div>

            <div className="flex-auto">
                <label htmlFor="phone" className="font-bold block mb-2">Phone</label>
                <InputMask id="phone" mask="(999) 999-9999" placeholder="(999) 999-9999"></InputMask>
            </div>

            <div className="flex-auto">
                <label htmlFor="serial" className="font-bold block mb-2">Serial</label>
                <InputMask id="serial" mask="a*-999-a999" placeholder="a*-999-a999"></InputMask>
            </div>
        </div>
    )
}
