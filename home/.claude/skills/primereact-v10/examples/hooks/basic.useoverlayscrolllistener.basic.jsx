const [bindOverlayScrollListener, unbindOverlayScrollListener] = useOverlayScrollListener({
    target: buttonRef.current,
    listener: handleScroll,
    options: { passive: true },
    when: visible
});
