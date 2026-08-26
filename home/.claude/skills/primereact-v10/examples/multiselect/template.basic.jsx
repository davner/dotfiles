<MultiSelect value={selectedCountries} options={countries} onChange={(e) => setSelectedCountries(e.value)} optionLabel="name" 
    placeholder="Select Countries" itemTemplate={countryTemplate} panelFooterTemplate={panelFooterTemplate} className="w-full md:w-20rem" display="chip" />
