import React from 'react';
import { ProgressBar } from 'primereact/progressbar';

export default function TemplateDemo() {
    const valueTemplate = (value) => {
        return (
            <React.Fragment>
                {value}/<b>100</b>
            </React.Fragment>
        );
    };

    return (
        <div className="card">
            <ProgressBar value={40} displayValueTemplate={valueTemplate}></ProgressBar>
        </div>
    );
}
