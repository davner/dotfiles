const [bindOverlayListener, unbindOverlayListener] = useOverlayListener({
    target: buttonRef.current,
    overlay: overlayRef.current,
    listener: handleScroll,
    options: { passive: true },
    when: visible
});
