useInterval(
    () => {
        setSeconds((prevSecond) => (prevSecond === 59 ? 0 : prevSecond + 1)); //fn
    },
    1000,   //delay (ms)
    active  //condition (when)
);
