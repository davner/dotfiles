import React from 'react'; 
import { Rating } from "primereact/rating";

export default function ReadOnlyDemo() {
    return (
        <div className="card flex justify-content-center">
            <Rating value={5} readOnly cancel={false} />
        </div>
    );
}
