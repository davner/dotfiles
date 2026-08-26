import React, { useState } from 'react';
import { OrganizationChart } from 'primereact/organizationchart';
import { TreeNode } from 'primereact/treenode';

export default function TemplateDemo() {
    const [data] = useState<TreeNode[]>([
        {
            label: 'Argentina',
            expanded: true,
            data: 'ar',
            children: [
                {
                    label: 'Argentina',
                    expanded: true,
                    data: 'ar',
                    children: [
                        {
                            label: 'Argentina',
                            data: 'ar'
                        },
                        {
                            label: 'Croatia',
                            data: 'hr'
                        }
                    ]
                },
                {
                    label: 'France',
                    expanded: true,
                    data: 'fr',
                    children: [
                        {
                            label: 'France',
                            data: 'fr'
                        },
                        {
                            label: 'Morocco',
                            data: 'ma'
                        }
                    ]
                }
            ]
        }
    ]);

    const nodeTemplate = (node: TreeNode) => {
        return (
            <div className="flex flex-column align-items-center">
                <img alt={node.label} src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png" className={`w-2rem shadow-2 flag flag-${node.data}`} />
                <div className="mt-3 font-medium text-lg">{node.label}</div>
            </div>
        );
    };

    return (
        <div className="card overflow-x-auto">
            <OrganizationChart value={data} nodeTemplate={nodeTemplate} />
        </div>
    )
}
