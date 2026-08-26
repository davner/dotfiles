const elementRef = useRef(null);
const visible = useIntersectionObserver(elementRef, { threshold: 0.5 });
