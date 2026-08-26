<ListBox value={selectedItem} onChange={(e) => setSelectedItem(e.value)} options={items} 
    virtualScrollerOptions={{ itemSize: 38 }} className="w-full md:w-14rem" listStyle={{ height: '250px' }} />
