import React from 'react'; 
import { Rating } from "primereact/rating";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Rating value={5} disabled cancel={false} />
        </div>
    );
}
