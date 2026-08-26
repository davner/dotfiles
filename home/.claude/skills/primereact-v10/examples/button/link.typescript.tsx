import React from 'react'; 
import { Button } from 'primereact/button';

export default function LinkDemo() {
    return (
        <div className="card flex justify-content-center">
            <Button label="Link" link onClick={() =>  window.open('https://react.dev', '_blank')}/>
            <a href="https://react.dev" target="_blank" rel="noopener noreferrer" className="p-button font-bold">
                Navigate
            </a>
        </div>
    )
}
