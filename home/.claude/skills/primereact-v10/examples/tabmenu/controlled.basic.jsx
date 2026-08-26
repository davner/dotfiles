<Button onClick={() => setActiveIndex(0)} className="p-button-outlined mb-5" label="Activate 1st" />
<TabMenu model={items} activeIndex={activeIndex} onTabChange={(e) => setActiveIndex(e.index)} />
