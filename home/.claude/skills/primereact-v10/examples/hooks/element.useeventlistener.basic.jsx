const [hover, setHover] = useState(false);
const elementRef = useRef(null);

const [bindMouseEnterListener, unbindMouseEnterListener] = useEventListener({
    target: elementRef,
    type: 'mouseenter',
    listener: () => {
        setHover(true);
    }
});

const [bindMouseLeaveListener, unbindMouseLeaveListener] = useEventListener({
    target: elementRef,
    type: 'mouseleave',
    listener: () => {
        setHover(false);
    }
});
