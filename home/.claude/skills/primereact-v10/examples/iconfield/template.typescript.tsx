import React from "react";
import { IconField } from "primereact/iconfield";
import { InputIcon } from "primereact/inputicon";
import { InputText } from "primereact/inputtext";

export default function TemplateDemo() {
    return (
        <IconField iconPosition="left">
            <InputIcon>
                <svg width="14" height="14" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <g mask="url(#mask0_2642_713)">
                        <path
                            fillRule="evenodd"
                            clipRule="evenodd"
                            d="..."
                            fill="var(--primary-color)"
                        />
                    </g>
                    <path d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                    <path
                        fillRule="evenodd"
                        clipRule="evenodd"
                        d="..."
                        fill="var(--primary-color)"
                    />
                    <path d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                    <path fillRule="evenodd" clipRule="evenodd" d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                    <path d="..." fill="var(--primary-color)" />
                </svg>
            </InputIcon>
            <InputText placeholder="Search" />
        </IconField>
    )
}
