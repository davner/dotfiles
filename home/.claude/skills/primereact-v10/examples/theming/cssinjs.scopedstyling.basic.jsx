import React from 'react';
import { Panel } from 'primereact/panel';
import css from 'styled-jsx/css';

export default function PanelDemo() {
    const {className, styles} = css.resolve`
        .p-panel > :global(.p-panel-header) {
            background-color: #54b5a6;
            color: #ffffff;
        }
    `;

    return (
        <>
            <style jsx>{styles}</style>
            <Panel header="CSS Module" className={className}>
                <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
                Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
                cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
            </Panel>
        </>
    )
}
