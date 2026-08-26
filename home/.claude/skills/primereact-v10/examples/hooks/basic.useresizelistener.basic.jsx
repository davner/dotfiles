const [bindWindowResizeListener, unbindWindowResizeListener] = useResizeListener({
    listener: (event) => {
        setEventData({
            width: event.currentTarget.innerWidth,
            height: event.currentTarget.innerHeight,
        })
    }
});
