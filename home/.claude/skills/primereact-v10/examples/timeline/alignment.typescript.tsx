import React from 'react'; 
import { Timeline } from 'primereact/timeline';

interface TimelineEvent {
    status?: string;
    date?: string;
    icon?: string;
    color?: string;
    image?: string;
}

export default function AlignmentDemo() {
    const events: TimelineEvent[] = [
        { status: 'Ordered', date: '15/10/2020 10:30', icon: 'pi pi-shopping-cart', color: '#9C27B0', image: 'game-controller.jpg' },
        { status: 'Processing', date: '15/10/2020 14:00', icon: 'pi pi-cog', color: '#673AB7' },
        { status: 'Shipped', date: '15/10/2020 16:15', icon: 'pi pi-shopping-cart', color: '#FF9800' },
        { status: 'Delivered', date: '16/10/2020 10:00', icon: 'pi pi-check', color: '#607D8B' }
    ];
        
    return (
        <div className="card flex flex-wrap gap-6">
            <Timeline value={events} content={(item) => item.status} className="w-full md:w-20rem" />
            <Timeline value={events} align="right" content={(item) => item.status} className="w-full md:w-20rem" />
            <Timeline value={events} align="alternate" content={(item) => item.status} className="w-full md:w-20rem" />
        </div>
    )
}
