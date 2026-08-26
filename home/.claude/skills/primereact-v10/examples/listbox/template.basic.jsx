<ListBox value={selectedCountry} onChange={(e) => setSelectedCountry(e.value)} options={countries} optionLabel="name" 
    itemTemplate={countryTemplate} className="w-full md:w-14rem" listStyle={{ maxHeight: '250px' }} />
