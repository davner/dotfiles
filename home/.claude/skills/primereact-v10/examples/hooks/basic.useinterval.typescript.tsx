import React from 'react'; 
import { Button } from 'primereact/button';
import { useInterval } from 'primereact/hooks';
import { classNames } from 'primereact/utils';

export default function BasicDemo() {
    const [seconds, setSeconds] = useState<number>(0);
    const [active, setActive] = useState<boolean>(true);

    useInterval(
        () => {
            setSeconds((prevSecond) => (prevSecond === 59 ? 0 : prevSecond + 1));
        },
        1000,
        active
    );

    return (
        <div className="card flex flex-column align-items-center">
            <div className="mb-3 font-bold text-4xl">{seconds}</div>
            <Button className={classNames('w-8rem p-button-outlined', { 'p-button-danger': active })}
                onClick={() => setActive(!active)} label={active ? 'Stop' : 'Resume'} />
        </div>
    )
}
