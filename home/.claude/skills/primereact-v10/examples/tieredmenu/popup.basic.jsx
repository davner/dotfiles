<TieredMenu model={items} popup ref={menu} breakpoint="767px" />
<Button label="Show" onClick={(e) => menu.current.toggle(e)} />
