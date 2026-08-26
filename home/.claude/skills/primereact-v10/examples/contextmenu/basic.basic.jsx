<ContextMenu model={items} ref={cm} breakpoint="767px" />
<img src="/images/nature/nature3.jpg" alt="Logo" className="max-w-full" onContextMenu={(e) => cm.current.show(e)} />
