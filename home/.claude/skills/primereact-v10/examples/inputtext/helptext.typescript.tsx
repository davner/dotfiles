import React from 'react'; 
import { InputText } from "primereact/inputtext";

export default function HelpTextDemo() {
    return (
        <div className="card flex justify-content-center">
            <div className="flex flex-column gap-2">
                <label htmlFor="username">Username</label>
                <InputText id="username" aria-describedby="username-help" />
                <small id="username-help">
                    Enter your username to reset your password.
                </small>
            </div>
        </div>
    )
}
