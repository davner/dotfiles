import React, { useState } from "react";
import { Rating, RatingChangeEvent} from "primereact/rating";

export default function TemplateDemo() {
    const [value, setValue] = useState<number>(null);

    return (
        <div className="card flex justify-content-center">
            <Rating value={value} onChange={(e: RatingChangeEvent) => setValue(e.value)}
                cancelIcon={<img src="https://primefaces.org/cdn/primereact/images/rating/cancel.png" alt="custom-cancel-image" width="25px" height="25px" />}
                onIcon={<img src="https://primefaces.org/cdn/primereact/images/rating/custom-icon-active.png" alt="custom-image-active" width="25px" height="25px" />}
                offIcon={<img src="https://primefaces.org/cdn/primereact/images/rating/custom-icon.png" alt="custom-image" width="25px" height="25px" />}
            />
        </div>
    );
}
