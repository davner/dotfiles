import React, { useState } from 'react'; 
import { PanelMenu } from 'primereact/panelmenu';
import { Button } from 'primereact/button';

export default function ControlledDemo() {
    const items = [
        {
            key: '0',
            label: 'Users',
            icon: 'pi pi-users',
            items: [
                {
                    key: '0_1',
                    label: 'New',
                    items: [
                        {
                            key: '0_1_0',
                            label: 'Member',
                        },
                        {
                            key: '0_1_1',
                            label: 'Group',
                        }
                    ]
                },
                {
                    key: '0_2',
                    label: 'Search',
                }
            ]
        },
        {
            key: '1',
            label: 'Tasks',
            icon: 'pi pi-server',
            items: [
                {
                    key: '1_0',
                    label: 'Add New',
                },
                {
                    key: '1_1',
                    label: 'Pending',
                },
                {
                    key: '1_2',
                    label: 'Overdue',
                }
            ]
        },
        {
            key: '2',
            label: 'Calendar',
            icon: 'pi pi-calendar',
            items: [
                {
                    key: '2_0',
                    label: 'New Event',
                },
                {
                    key: '2_1',
                    label: 'Today',
                },
                {
                    key: '2_2',
                    label: 'This Week',
                }
            ]
        }
    ];

    const [expandedKeys, setExpandedKeys] = useState<any>({});

    const toggleAll = () => {
        if (Object.keys(expandedKeys).length) {
            collapseAll();
        } else {
            expandAll();
        }
    };

    const expandAll = () => {
        items.forEach(expandNode);
        setExpandedKeys({ ...expandedKeys });
    };

    const collapseAll = () => {
        setExpandedKeys({});
    };

    const expandNode = (node) => {
        if (node.items && node.items.length) {
            expandedKeys[node.key] = true;

            node.items.forEach(expandNode);
        }
    };

    return (
        <div className="card flex flex-column align-items-center gap-3">
            <Button type="button" label="Toggle All" text onClick={() => toggleAll()} />
            <PanelMenu model={items} expandedKeys={expandedKeys} onExpandedKeysChange={setExpandedKeys} className="w-full md:w-20rem" multiple />
            </div>
    )
}
